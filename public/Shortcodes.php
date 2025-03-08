class Shortcodes {
    public function __construct() {
        add_shortcode('adversarial_code_generator', [$this, 'code_generator_shortcode']);
    }

    public function code_generator_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-generator">
            <h2><?php esc_html_e('Generate Code', 'adversarial-code-generator'); ?></h2>
            <form method="post" class="adversarial-generator-form">
                <?php wp_nonce_field('adversarial_generate_code', 'adversarial_nonce'); ?>
                <div class="form-group">
                    <label for="code_prompt"><?php esc_html_e('Code Request:', 'adversarial-code-generator'); ?></label>
                    <textarea id="code_prompt" name="code_prompt" rows="10" class="large-text code" placeholder="<?php esc_attr_e('Enter your code generation request...', 'adversarial-code-generator'); ?>"></textarea>
                </div>
                <div class="form-group">
                    <label for="features"><?php esc_html_e('Additional Features (optional):', 'adversarial-code-generator'); ?></label>
                    <textarea id="features" name="features" rows="5" class="large-text code" placeholder="<?php esc_attr_e('Enter additional features to implement after initial code generation...', 'adversarial-code-generator'); ?>"></textarea>
                </div>
                <div class="form-group">
                    <label for="language"><?php esc_html_e('Programming Language:', 'adversarial-code-generator'); ?></label>
                    <select id="language" name="language" class="regular-text">
                        <option value="python" selected>Python</option>
                        <option value="javascript">JavaScript</option>
                        <option value="typescript">TypeScript</option>
                        <option value="java">Java</option>
                        <option value="cpp">C++</option>
                        <option value="csharp">C#</option>
                        <option value="go">Go</option>
                        <option value="ruby">Ruby</option>
                        <option value="php">PHP</option>
                    </select>
                </div>
                <button type="submit" class="button button-primary"><?php esc_html_e('Generate Code', 'adversarial-code-generator'); ?></button>
                <div class="loading-indicator" style="display: none;">
                    <p><?php esc_html_e('Generating code... Please wait.', 'adversarial-code-generator'); ?></p>
                </div>
            </form>
            
            <div class="results-container" style="display: none;">
                <div class="notice notice-success">
                    <p><?php esc_html_e('Code generation successful!', 'adversarial-code-generator'); ?></p>
                </div>
                <div class="generated-code">
                    <pre><code class="language-python"></code></pre>
                </div>
                <div class="generation-stats">
                    <p><?php esc_html_e('Iterations: ', 'adversarial-code-generator'); ?><span class="iterations"></span></p>
                    <p><?php esc_html_e('Duration: ', 'adversarial-code-generator'); ?><span class="duration"></span>s</p>
                    <p><?php esc_html_e('Features implemented: ', 'adversarial-code-generator'); ?><span class="features-implemented"></span>/<span class="total-features"></span></p>
                </div>
            </div>
            
            <div class="error-container" style="display: none;">
                <div class="notice notice-error">
                    <p></p>
                </div>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
}