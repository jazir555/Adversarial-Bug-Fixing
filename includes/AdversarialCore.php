class AdversarialCore {
    private static $instance;
    public $settings;
    public $logger;
    public $workflow_manager;
    
    private function __construct() {
        $this->settings = new Settings();
        $this->logger = new Logger();
        $this->workflow_manager = new WorkflowManager();
        
        // Initialize other components
        new LLMHandler();
        new Security();
        new Analytics();
        new UserCapabilities();
        new HelpDocumentation();
        new CodeEditor();
        new CodeComparison();
        new UnitTesting();
        new CodeReview();
        new CodeTemplates();
        new Collaboration();
        new PerformanceOptimizer();
        new MobileUI();
        new CodeExport();
        new CodeImport();
        new CodeHistory();
        new AdvancedSecurity();
        new CodePerformance();
        new RealTimeCollaboration();
        new AdvancedAnalytics();
        new CodeFormatter();
        new TranslationSupport();
        new CodeDiffViewer();
        new CodeComments();
        new CodeSnippets();
        new PrivateLLMSupport();
        new ThemeSwitcher();
        new CodeSharing();
        new CodeExecutionTimeout();
        new ActivityLogging();
        new CodeMinifier();
        new AutoSave();
        new CodeEnvironment();
        new CIIntegration();
        new CodeAnalysis();
        new OnboardingTutorial();
        new CodeTranslation();
        new CodeRefactoring();
    }
    
    public static function get_instance() {
        if (!self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    public function run_onboarding_tutorial() {
        $tutorial = new OnboardingTutorial();
        $tutorial->show_onboarding_tutorial();
    }
}