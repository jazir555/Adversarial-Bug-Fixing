class CodeAnalysis {
    public function analyze_code_quality($code, $language) {
        $prompt = "Perform a comprehensive quality analysis of the following " . $language . " code:\n\n" . $code . 
                  "\n\nEvaluate code readability, maintainability, adherence to best practices, and potential improvements.";
        
        $llm_handler = new LLMHandler();
        return $llm_handler->call_llm_api($llm_handler->select_model('analysis'), $prompt, 'analyze_code', $language);
    }
}