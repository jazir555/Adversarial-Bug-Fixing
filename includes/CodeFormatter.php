class CodeFormatter {
    public function format_code($code, $language) {
        $prompt = "Format the following " . $language . " code according to the language's best practices:\n\n" . $code;
        
        $llm_handler = new LLMHandler();
        return $llm_handler->call_llm_api($llm_handler->select_model('formatting'), $prompt, 'format_code', $language);
    }
}