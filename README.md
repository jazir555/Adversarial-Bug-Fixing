# AI LLM generating code based on a given prompt (e.g., "Build me a recipe maker and generate a recipe for a sandwich.").

Adversarial Bug Checking – The generated code is then automatically routed to multiple LLMs (e.g., Claude and Gemini) for bug detection.

Bug Aggregation & Fixes – The detected bugs are collected, and another LLM (or the same one) implements the necessary fixes.

Iterative Improvement – This loop continues until all participating LLMs agree that the code is bug-free.

Final Debugging & Logging – The refined code is run through a debugger, with errors logged and additional debugging handled through an automated process.

This approach essentially enables bug fixing by committee, leveraging the strengths of different models to improve reliability and robustness.

Configurable Parameters
To enhance flexibility, users should be able to configure:

Choice of LLMs – Select which model generates the initial code and which ones review for bugs.
Bug-Fixing Implementation – Define which model applies fixes, with options for fixed selection, random rotation, or round-based rotation.
Iteration Limit – Set a max number of bug-checking rounds (e.g., a loop of 3, 5, etc.).
Feature Expansion Rules – Introduce additional features at predefined steps (e.g., at round 5, request and implement a new feature before continuing the bug-fixing process).
Time & Resource Constraints – Limit the process by time (e.g., run for X minutes/hours) or API usage (e.g., cap at Y code generations).
Enhanced Workflow with Feature Expansion
To take this further, the system could incorporate stepwise feature addition:

Round 1: Initial code generation
Rounds 2-4: Bug checking and fixes
Round 5: Request and implement additional feature ideas
Rounds 6-8: Bug checking and refining the new feature
Repeat until conditions are met
This structure enables automated iterative development, where new functionality is incrementally added and tested without manual intervention.
