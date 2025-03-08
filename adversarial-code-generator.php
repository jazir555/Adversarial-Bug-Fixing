<?php
/*
Plugin Name: Adversarial Code Generator
Description: Generates and refines code using multiple LLMs through adversarial testing.
Version: 1.2
Author: Your Name
Text Domain: adversarial-code-generator
*/

if (!defined('ABSPATH')) {
    exit;
}

// Define plugin constants
define('ADVERSARIAL_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('ADVERSARIAL_PLUGIN_URL', plugin_dir_url(__FILE__));
define('ADVERSARIAL_VERSION', '1.2');

// Include required classes
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/AdversarialCore.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/LLMHandler.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/WorkflowManager.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Settings.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Logger.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Security.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/Analytics.php';
require_once ADVERSARIAL_PLUGIN_DIR . 'includes/RESTAPI.php';

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
}
register_activation_hook(__FILE__, 'adversarial_code_generator_activate');

// Deactivation hook
function adversarial_code_generator_deactivate() {
    // Cleanup resources if needed
}
register_deactivation_hook(__FILE__, 'adversarial_code_generator_deactivate');