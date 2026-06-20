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
    const { sender_id, recipient_id } = await req.json()
    if (!sender_id || !recipient_id) throw new Error('Missing sender_id or recipient_id')

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    // 1. Fetch Recipient's Profile
    const { data: recipientData, error: recipientError } = await supabaseAdmin
      .from('users')
      .select('onboarding_profile')
      .eq('id', recipient_id)
      .single()

    if (recipientError || !recipientData) throw new Error('Failed to fetch recipient profile')
    const onboardingProfile = recipientData.onboarding_profile || {}

    // 2. Fetch Prompt
    const { data: promptData, error: promptError } = await supabaseAdmin
      .from('ai_prompts')
      .select('prompt_text')
      .eq('id', 'social_growth_drop')
      .single()
      
    if (promptError) throw new Error('Failed to fetch prompt')

    // 3. Call OpenAI
    const apiKey = Deno.env.get('OPENAI_API_KEY')
    if (!apiKey) throw new Error('Missing OPENAI_API_KEY')
    
    const openai = new OpenAI({ apiKey })
    const systemPrompt = promptData.prompt_text
    const userPrompt = `
    Friend's Profile: ${JSON.stringify(onboardingProfile)}
    
    Please generate 1 highly relevant non-fiction book drop tailored to this friend.
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
    
    const today = new Date().toISOString().split('T')[0]

    // 4. Insert into social_drops table
    const { data: dropData, error: insertError } = await supabaseAdmin
      .from('social_drops')
      .insert({
        sender_id: sender_id,
        recipient_id: recipient_id,
        drop_date: today,
        book_data: resultJson
      })
      .select()
      .single()

    if (insertError) throw new Error('Failed to insert social drop: ' + insertError.message)

    // 5. Update Streak
    const { data: streakData } = await supabaseAdmin
      .from('social_streaks')
      .select('*')
      .or(`and(user_id_1.eq.${sender_id},user_id_2.eq.${recipient_id}),and(user_id_1.eq.${recipient_id},user_id_2.eq.${sender_id})`)
      .single()

    if (streakData) {
        let isUser1 = streakData.user_id_1 === sender_id;
        let updatePayload: any = {};
        if (isUser1) {
            updatePayload.last_shared_date_1 = today;
            if (streakData.last_shared_date_2 === today) {
                updatePayload.current_streak = (streakData.current_streak || 0) + 1;
            }
        } else {
            updatePayload.last_shared_date_2 = today;
            if (streakData.last_shared_date_1 === today) {
                updatePayload.current_streak = (streakData.current_streak || 0) + 1;
            }
        }
        await supabaseAdmin.from('social_streaks').update(updatePayload).eq('id', streakData.id)
    } else {
        await supabaseAdmin.from('social_streaks').insert({
            user_id_1: sender_id,
            user_id_2: recipient_id,
            last_shared_date_1: today,
            current_streak: 0
        })
    }

    return new Response(JSON.stringify({ success: true, data: dropData }), {
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
