class CodeQualityAnalyzer {
    private $llm_handler;
    
    public function __construct() {
        $this->llm_handler = new LLMHandler();
    }
    
    public function analyze($code, $language) {
        try {
            return $this->llm_handler->analyze_code_quality($code, $language);
        } catch (Exception $e) {
            throw new Exception("Code quality analysis failed: " . $e->getMessage());
        }
    }
}