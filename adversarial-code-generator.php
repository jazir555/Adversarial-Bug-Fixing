<?php
/*
Plugin Name: Adversarial Code Generator
Description: Generates and refines code using multiple LLMs through adversarial testing.
Version: 2.1
Author: Your Name
Text Domain: adversarial-code-generator
*/

if (!defined('ABSPATH')) {
    exit;
}

// Define plugin constants
define('ADVERSARIAL_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('ADVERSARIAL_PLUGIN_URL', plugin_dir_url(__FILE__));
define('ADVERSARIAL_VERSION', '2.1');

// Include required classes
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/AdversarialCore.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/LLMHandler.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/WorkflowManager.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Settings.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Logger.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Security.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Analytics.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/RESTAPI.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/UserCapabilities.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Sandbox.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/GitIntegration.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/HelpDocumentation.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeEditor.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeComparison.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/UnitTesting.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeReview.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeTemplates.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Collaboration.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/PerformanceOptimizer.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/MobileUI.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeExport.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeImport.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeHistory.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/AdvancedSecurity.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodePerformance.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/RealTimeCollaboration.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/AdvancedAnalytics.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeFormatter.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/TranslationSupport.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeDiffViewer.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeComments.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeSnippets.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/PrivateLLMSupport.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/ThemeSwitcher.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeSharing.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeExecutionTimeout.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/ActivityLogging.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeMinifier.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/AutoSave.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeEnvironment.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CIIntegration.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeAnalysis.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/OnboardingTutorial.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeTranslation.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/CodeRefactoring.php';

// Admin components
require_once ADVERSARIAL_PLUGIN_DIR . 'admin/AdminSettings.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'admin/AdminUI.php';

// Public components
require_once ADVERSARIAL_PLUGIN_DIR . 'public/PublicUI.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'public/Shortcodes.php';

// Initialize plugin
function adversarial_code_generator_init() {
    new AdversarialCore();
    new AdminSettings();
    new PublicUI();
    new RESTAPI();
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
add_action('plugins_loaded', 'adversarial_code_generator_init');

// Activation hook
function adversarial_code_generator_activate() {
    // Create necessary database tables
    require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Database.php';
    Database::install();
    
    // Create uploads directory
    $upload_dir = wp_upload_dir();
    $plugin_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator';
    wp_mkdir_p($plugin_dir . '/cache');
    wp_mkdir_p($plugin_dir . '/logs');
    wp_mkdir_p($plugin_dir . '/exports');
    wp_mkdir_p($plugin_dir . '/sandbox');
    wp_mkdir_p($plugin_dir . '/git_repos');
    wp_mkdir_p($plugin_dir . '/templates');
    wp_mkdir_p($plugin_dir . '/collaboration');
    wp_mkdir_p($plugin_dir . '/history');
    wp_mkdir_p($plugin_dir . '/performance');
    wp_mkdir_p($plugin_dir . '/translations');
    wp_mkdir_p($plugin_dir . '/snippets');
    wp_mkdir_p($plugin_dir . '/comments');
    wp_mkdir_p($plugin_dir . '/shares');
    wp_mkdir_p($plugin_dir . '/environments');
    wp_mkdir_p($plugin_dir . '/ci_pipelines');
    wp_mkdir_p($plugin_dir . '/analysis');
    wp_mkdir_p($plugin_dir . '/tutorials');
    wp_mkdir_p($plugin_dir . '/refactoring');
}
register_activation_hook(__FILE__, 'adversarial_code_generator_activate');

// Deactivation hook
function adversarial_code_generator_deactivate() {
    // Cleanup resources if needed
}
register_deactivation_hook(__FILE__, 'adversarial_code_generator_deactivate');