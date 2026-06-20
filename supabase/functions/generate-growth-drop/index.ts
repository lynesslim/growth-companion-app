import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "npm:@supabase/supabase-js@2"
import OpenAI from "npm:openai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, onboarding_profile, drop_date } = await req.json()

    // Create Supabase Admin client to bypass RLS for inserting growth drop
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    // 1. Fetch Prompt
    const { data: promptData, error: promptError } = await supabaseAdmin
      .from('ai_prompts')
      .select('prompt_text')
      .eq('id', 'daily_growth_drop')
      .single()
      
    if (promptError) throw new Error('Failed to fetch prompt: ' + promptError.message)

    // 1.5 Fetch Past Books to Avoid Repeats
    const { data: pastGrowth } = await supabaseAdmin.from('growth_drops').select('recommended_books').eq('user_id', user_id)
    const { data: pastSocial } = await supabaseAdmin.from('social_drops').select('book_data').eq('recipient_id', user_id).eq('is_opened', true)
    
    const pastTitles: string[] = []
    if (pastGrowth) {
        pastGrowth.forEach((d: any) => { 
          if (Array.isArray(d.recommended_books)) {
            d.recommended_books.forEach((b: any) => {
              if (b?.bookTitle) pastTitles.push(b.bookTitle)
            })
          }
        })
    }
    if (pastSocial) {
        pastSocial.forEach((d: any) => { if (d.book_data?.bookTitle) pastTitles.push(d.book_data.bookTitle) })
    }
    const avoidString = pastTitles.length > 0 ? `DO NOT RECOMMEND ANY OF THESE PAST BOOKS: ${pastTitles.join(', ')}` : ''

    // 2. Call OpenAI
    const apiKey = Deno.env.get('OPENAI_API_KEY')
    if (!apiKey) throw new Error('Missing OPENAI_API_KEY')
    
    const openai = new OpenAI({ apiKey })
    
    const systemPrompt = promptData.prompt_text
    const userPrompt = `
    User Profile: ${JSON.stringify(onboarding_profile)}
    
    Please generate 1 highly relevant non-fiction book drop for this specific user.
    Random seed to ensure variety on regeneration: ${Math.random()}
    
    ${avoidString}
    `
    
    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      response_format: { type: "json_object" }
    })

    const resultStr = response.choices[0].message?.content
    const resultJson = JSON.parse(resultStr || '{}')
    
    const focusArea = (onboarding_profile && onboarding_profile.goals) ? onboarding_profile.goals.split(',')[0] : 'Personal Growth'

    // 3. Insert into growth_drops table
    const { error: insertError } = await supabaseAdmin
      .from('growth_drops')
      .insert({
        user_id: user_id,
        drop_date: drop_date,
        focus_area: focusArea,
        recommended_books: [resultJson] // Passed as an array of 1 book to maintain schema backwards compatibility
      })

    if (insertError) throw new Error('Failed to insert growth drop: ' + insertError.message)

    return new Response(JSON.stringify({ success: true, data: resultJson }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
