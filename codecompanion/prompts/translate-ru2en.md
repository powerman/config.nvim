---
name: Translate ru2en
interaction: chat
description: Translate from Russian to English
opts:
  adapter:
    name: ollama
    model: translategemma:4b
  alias: 2en
  auto_submit: false
  ignore_system_prompt: true
  modes:
    - i
    - n
    - v
  stop_context_insertion: false
---

## user

You are a professional Russian (ru) to English (en) translator. Your goal is to accurately convey the meaning and nuances of the original Russian text while adhering to English grammar, vocabulary, and cultural sensitivities.
Produce only the English translation, without any additional explanations or commentary. Please translate the following Russian text into English:
 
 
 ${const.EOF}
