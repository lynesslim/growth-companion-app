import 'dart:convert';
import 'dart:io';

void main() {
  final socialFile = File('/Users/lynesslim/.gemini/antigravity-ide/brain/d975a66c-6e4e-4867-bf1d-076446e2ac7f/.system_generated/steps/977/output.txt');
  final dailyFile = File('/Users/lynesslim/.gemini/antigravity-ide/brain/d975a66c-6e4e-4867-bf1d-076446e2ac7f/.system_generated/steps/983/output.txt');
  
  String updatePrompt(String rawText) {
    // Extract JSON part
    final resultStr = jsonDecode(rawText)['result'] as String;
    final startJson = resultStr.indexOf('[');
    final endJson = resultStr.lastIndexOf(']') + 1;
    final jsonStr = resultStr.substring(startJson, endJson);
    final arr = jsonDecode(jsonStr) as List;
    String promptText = arr.first['prompt_text'];

    // 1. Update JSON Schema
    promptText = promptText.replaceFirst(
      '"summary": "1. First takeaway under ten words.\\n2. Second takeaway under ten words.\\n3. Third takeaway under ten words.\\n\\nQuote: \\"A real quote from the book or a real relevant quote from the author/book context.\\""\n}',
      '"summary": "1. First takeaway under ten words.\\n2. Second takeaway under ten words.\\n3. Third takeaway under ten words.\\n\\nQuote: \\"A real quote from the book or a real relevant quote from the author/book context.\\"",\n"coverUrl": "<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 400 600\\"><defs><linearGradient id=\\"grad\\" x1=\\"0%\\" y1=\\"0%\\" x2=\\"100%\\" y2=\\"100%\\"><stop offset=\\"0%\\" stop-color=\\"#FF7A00\\"/><stop offset=\\"100%\\" stop-color=\\"#FF004D\\"/></linearGradient></defs><rect width=\\"400\\" height=\\"600\\" fill=\\"url(#grad)\\"/><circle cx=\\"200\\" cy=\\"300\\" r=\\"150\\" fill=\\"#FFFFFF\\" fill-opacity=\\"0.1\\"/></svg>"\n}'
    );

    // 2. Add SVG constraints to OUTPUT REQUIREMENTS
    promptText = promptText.replaceFirst(
      'OUTPUT REQUIREMENTS\n\n',
      'OUTPUT REQUIREMENTS\n\n* You MUST generate a visually beautiful, abstract SVG background in the `coverUrl` field. Use ONLY standard vector shapes (<rect>, <circle>, <path>, <polygon>, <defs>, <linearGradient>). DO NOT INCLUDE ANY TEXT IN THE SVG. The SVG should be purely decorative and reflect the mood/theme of the book. DO NOT use <style> blocks, CSS classes, or <foreignObject>. Inline all styling.\n'
    );
    
    return promptText.replaceAll("'", "''");
  }
  
  final socialSql = "UPDATE ai_prompts SET prompt_text = '" + updatePrompt(socialFile.readAsStringSync()) + "' WHERE id = 'social_growth_drop';";
  final dailySql = "UPDATE ai_prompts SET prompt_text = '" + updatePrompt(dailyFile.readAsStringSync()) + "' WHERE id = 'daily_growth_drop';";
  
  File('fix_prompts_bg.sql').writeAsStringSync(socialSql + "\n" + dailySql);
  print('Done writing fix_prompts_bg.sql');
}
