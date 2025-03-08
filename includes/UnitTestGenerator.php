class UnitTestGenerator {
    private $llm_handler;
    
    public function __construct() {
        $this->llm_handler = new LLMHandler();
    }
    
    public function generate_tests($code, $language) {
        try {
            return $this->llm_handler->generate_tests($code, $language);
        } catch (Exception $e) {
            throw new Exception("Test generation failed: " . $e->getMessage());
        }
    }
}