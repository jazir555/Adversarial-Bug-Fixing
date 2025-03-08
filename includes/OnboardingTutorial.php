class OnboardingTutorial {
    public function __construct() {
        add_action('admin_init', [$this, 'register_settings']);
        add_action('adversarial_code_generator_onboarding', [$this, 'show_onboarding_tutorial']);
    }

    public function register_settings() {
        register_setting('adversarial_settings', 'adversarial_onboarding_completed');
    }

    public function show_onboarding_tutorial() {
        if (get_option('adversarial_onboarding_completed')) {
            return;
        }
        
        ?>
        <div class="adversarial-onboarding-tutorial">
            <div class="tutorial-header">
                <h2><?php esc_html_e('Welcome to Adversarial Code Generator!', 'adversarial-code-generator'); ?></h2>
                <p><?php esc_html_e('This quick tutorial will help you get started with the plugin.', 'adversarial-code-generator'); ?></p>
            </div>
            
            <div class="tutorial-steps">
                <div class="tutorial-step active" data-step="1">
                    <h3><?php esc_html_e('Step 1: Configuration', 'adversarial-code-generator'); ?></h3>
                    <p><?php esc_html_e('Configure your LLM API keys in the settings page.', 'adversarial-code-generator'); ?></p>
                    <button class="button next-step"><?php esc_html_e('Next', 'adversarial-code-generator'); ?></button>
                </div>
                
                <div class="tutorial-step" data-step="2">
                    <h3><?php esc_html_e('Step 2: Generating Code', 'adversarial-code-generator'); ?></h3>
                    <p><?php esc_html_e('Use the code generator to create your first piece of code.', 'adversarial-code-generator'); ?></p>
                    <button class="button next-step"><?php esc_html_e('Next', 'adversarial-code-generator'); ?></button>
                </div>
                
                <div class="tutorial-step" data-step="3">
                    <h3><?php esc_html_e('Step 3: Refining Code', 'adversarial-code-generator'); ?></h3>
                    <p><?php esc_html_e('Learn how to refine and improve your generated code.', 'adversarial-code-generator'); ?></p>
                    <button class="button next-step"><?php esc_html_e('Next', 'adversarial-code-generator'); ?></button>
                </div>
                
                <div class="tutorial-step" data-step="4">
                    <h3><?php esc_html_e('Step 4: Execution', 'adversarial-code-generator'); ?></h3>
                    <p><?php esc_html_e('Execute your code in a secure sandbox environment.', 'adversarial-code-generator'); ?></p>
                    <button class="button next-step"><?php esc_html_e('Next', 'adversarial-code-generator'); ?></button>
                </div>
                
                <div class="tutorial-step" data-step="5">
                    <h3><?php esc_html_e('Step 5: Collaboration', 'adversarial-code-generator'); ?></h3>
                    <p><?php esc_html_e('Explore collaboration features for team projects.', 'adversarial-code-generator'); ?></p>
                    <button class="button complete-tutorial"><?php esc_html_e('Complete Tutorial', 'adversarial-code-generator'); ?></button>
                </div>
            </div>
        </div>
        <?php
    }

    public function complete_tutorial() {
        update_option('adversarial_onboarding_completed', true);
    }
}