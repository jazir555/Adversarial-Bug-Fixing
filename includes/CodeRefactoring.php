class CodeRefactoring {
    public function refactor_code($code, $language, $goal) {
        $prompt = "Refactor the following " . $language . " code to achieve the following goal: " . $goal . "\n\n" . $code;
        
        $llm_handler = new LLMHandler();
        return $llm_handler->call_llm_api($llm_handler->select_model('refactoring'), $prompt, 'refactor_code', $language);
    }
}