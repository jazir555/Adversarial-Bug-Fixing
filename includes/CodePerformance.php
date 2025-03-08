class CodePerformance {
    public function analyze_code_performance($code, $language) {
        $prompt = "Analyze the performance of the following " . $language . " code:\n\n" . $code . 
                  "\n\nIdentify potential bottlenecks, suggest optimizations, and provide recommendations for improving performance.";
        
        $llm_handler = new LLMHandler();
        return $llm_handler->call_llm_api($llm_handler->select_model('performance'), $prompt, 'analyze_performance', $language);
    }

    public function optimize_code($code, $language) {
        $prompt = "Optimize the following " . $language . " code for performance:\n\n" . $code . 
                  "\n\nApply appropriate optimizations while maintaining code readability and functionality.";
        
        $llm_handler = new LLMHandler();
        return $llm_handler->call_llm_api($llm_handler->select_model('optimization'), $prompt, 'optimize_code', $language);
    }
}