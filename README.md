# NodeRed Automation to automatically bug check code using adversarial testing via multiple chatbots.

Automatically installs and configures a NodeRed environment with a simple WebUI to interact with multiple AI chatbots to bug check code. APIs are used to adversarially bug test code between 2 or more specified bots after providing API keys for each. The code that is desired to be bug checked is pulled from a github repo, which requires a user provided API key for authentication to link the WebUI to that repo. Once attached, the user specifies file names for up to 5 separate prompts which are rotated randomly after each bug check by a bot to ensure multiple runs are performed with varying prompts.

For example, Claude and ChatGPT.  
