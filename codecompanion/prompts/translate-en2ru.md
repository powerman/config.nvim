---
name: Translate en2ru
interaction: chat
description: Translate from English to Russian
opts:
  adapter:
    name: ollama
    model: translategemma:4b
  alias: 2ru
  auto_submit: false
  ignore_system_prompt: true
  modes:
    - i
    - n
    - v
  stop_context_insertion: false
---

## user

You are a professional English (en) to Russian (ru) translator. Your goal is to accurately convey the meaning and nuances of the original English text while adhering to Russian grammar, vocabulary, and cultural sensitivities.
Produce only the Russian translation, without any additional explanations or commentary. Please translate the following English text into Russian:
 
 
 ${const.EOF}
