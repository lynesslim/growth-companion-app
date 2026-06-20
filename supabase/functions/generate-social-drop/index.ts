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
    const { drop_id } = await req.json()
    if (!drop_id) throw new Error('Missing drop_id')

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    // 1. Fetch the social drop to get recipient
    const { data: dropData, error: dropError } = await supabaseAdmin
      .from('social_drops')
      .select('sender_id, recipient_id')
      .eq('id', drop_id)
      .single()

    if (dropError || !dropData) throw new Error('Failed to fetch social drop')

    const { recipient_id } = dropData

    // 2. Fetch Recipient's Profile
    const { data: recipientData, error: recipientError } = await supabaseAdmin
      .from('profiles')
      .select('onboarding_profile')
      .eq('id', recipient_id)
      .single()

    if (recipientError || !recipientData) throw new Error('Failed to fetch recipient profile')
    const onboardingProfile = recipientData.onboarding_profile || {}

    // 3. Fetch Prompt
    const { data: promptData, error: promptError } = await supabaseAdmin
      .from('ai_prompts')
      .select('prompt_text')
      .eq('id', 'social_growth_drop')
      .single()
      
    if (promptError) throw new Error('Failed to fetch prompt')

    // 4. Call OpenAI
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

    // 5. Update the social_drop with generated book_data
    const { error: updateError } = await supabaseAdmin
      .from('social_drops')
      .update({ book_data: resultJson })
      .eq('id', drop_id)

    if (updateError) throw new Error('Failed to update social drop: ' + updateError.message)

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
