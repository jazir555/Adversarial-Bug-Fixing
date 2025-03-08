class Shortcodes {
    public function __construct() {
        add_shortcode('adversarial_code_generator', [$this, 'code_generator_shortcode']);
        add_shortcode('adversarial_code_executor', [$this, 'code_executor_shortcode']);
        add_shortcode('adversarial_git_clone', [$this, 'git_clone_shortcode']);
        add_shortcode('adversarial_code_template', [$this, 'code_template_shortcode']);
        add_shortcode('adversarial_template_library', [$this, 'template_library_shortcode']);
        add_shortcode('adversarial_collaboration', [$this, 'collaboration_shortcode']);
        add_shortcode('adversarial_code_history', [$this, 'history_shortcode']);
        add_shortcode('adversarial_security_scan', [$this, 'security_scan_shortcode']);
        add_shortcode('adversarial_code_format', [$this, 'code_format_shortcode']);
        add_shortcode('adversarial_code_translate', [$this, 'code_translate_shortcode']);
    }

    public function security_scan_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-security-scan">
            <h2><?php esc_html_e('Security Scan', 'adversarial-code-generator'); ?></h2>
            <form method="post" class="security-scan-form">
                <?php wp_nonce_field('adversarial_security_scan', 'adversarial_nonce'); ?>
                <div class="form-group">
                    <label for="code_to_scan"><?php esc_html_e('Code to Scan:', 'adversarial-code-generator'); ?></label>
                    <div class="code-editor-wrapper code-to-scan" data-language="python" data-theme="monokai" style="height: 200px;"></div>
                    <input type="hidden" class="code-to-scan-value" name="code_to_scan_value" value="">
                </div>
                <div class="form-group">
                    <label for="language"><?php esc_html_e('Programming Language:', 'adversarial-code-generator'); ?></label>
                    <select id="language" name="language" class="regular-text">
                        <option value="python" selected>Python</option>
                        <option value="javascript">JavaScript</option>
                        <option value="java">Java</option>
                        <option value="php">PHP</option>
                        <option value="cpp">C++</option>
                        <option value="csharp">C#</option>
                        <option value="go">Go</option>
                        <option value="ruby">Ruby</option>
                    </select>
                </div>
                <button type="submit" class="button button-primary"><?php esc_html_e('Run Security Scan', 'adversarial-code-generator'); ?></button>
            </form>
            
            <?php
            if (isset($_POST['code_to_scan_value']) && wp_verify_nonce($_POST['adversarial_nonce'], 'adversarial_security_scan')) {
                try {
                    $code = sanitize_textarea_field($_POST['code_to_scan_value']);
                    $language = isset($_POST['language']) ? sanitize_text_field($_POST['language']) : 'python';
                    
                    $security = new AdvancedSecurity();
                    $findings = $security->scan_for_vulnerabilities($code);
                    
                    echo '<div class="notice notice-success"><p>' . esc_html__('Security scan completed!', 'adversarial-code-generator') . '</p></div>';
                    echo '<div class="scan-results">';
                    if (empty($findings)) {
                        echo '<p>' . esc_html__('No vulnerabilities found.', 'adversarial-code-generator') . '</p>';
                    } else {
                        echo '<h3>' . esc_html__('Found Vulnerabilities', 'adversarial-code-generator') . '</h3>';
                        foreach ($findings as $finding) {
                            echo '<div class="vulnerability-item">';
                            echo '<h4>' . esc_html($finding['title']) . '</h4>';
                            echo '<p>' . esc_html($finding['description']) . '</p>';
                            echo '<p><strong>' . esc_html__('Severity: ', 'adversarial-code-generator') . '</strong>' . esc_html($finding['severity']) . '</p>';
                            echo '<p><strong>' . esc_html__('References: ', 'adversarial-code-generator') . '</strong><br>' . implode('<br>', $finding['references']) . '</p>';
                            echo '</div>';
                        }
                    }
                    echo '</div>';
                } catch (Exception $e) {
                    echo '<div class="notice notice-error"><p>' . esc_html__('Security scan failed: ', 'adversarial-code-generator') . esc_html($e->getMessage()) . '</p></div>';
                }
            }
            ?>
        </div>
        <?php
        return ob_get_clean();
    }

    public function code_format_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-format">
            <h2><?php esc_html_e('Code Formatter', 'adversarial-code-generator'); ?></h2>
            <form method="post" class="code-format-form">
                <?php wp_nonce_field('adversarial_code_format', 'adversarial_nonce'); ?>
                <div class="form-group">
                    <label for="code_to_format"><?php esc_html_e('Code to Format:', 'adversarial-code-generator'); ?></label>
                    <div class="code-editor-wrapper code-to-format" data-language="python" data-theme="monokai" style="height: 200px;"></div>
                    <input type="hidden" class="code-to-format-value" name="code_to_format_value" value="">
                </div>
                <div class="form-group">
                    <label for="language"><?php esc_html_e('Programming Language:', 'adversarial-code-generator'); ?></label>
                    <select id="language" name="language" class="regular-text">
                        <option value="python" selected>Python</option>
                        <option value="javascript">JavaScript</option>
                        <option value="java">Java</option>
                        <option value="php">PHP</option>
                        <option value="cpp">C++</option>
                        <option value="csharp">C#</option>
                        <option value="go">Go</option>
                        <option value="ruby">Ruby</option>
                    </select>
                </div>
                <button type="submit" class="button button-primary"><?php esc_html_e('Format Code', 'adversarial-code-generator'); ?></button>
            </form>
            
            <?php
            if (isset($_POST['code_to_format_value']) && wp_verify_nonce($_POST['adversarial_nonce'], 'adversarial_code_format')) {
                try {
                    $code = sanitize_textarea_field($_POST['code_to_format_value']);
                    $language = isset($_POST['language']) ? sanitize_text_field($_POST['language']) : 'python';
                    
                    $formatter = new CodeFormatter();
                    $formatted_code = $formatter->format_code($code, $language);
                    
                    echo '<div class="notice notice-success"><p>' . esc_html__('Code formatted successfully!', 'adversarial-code-generator') . '</p></div>';
                    echo '<div class="formatted-code"><pre>' . esc_html($formatted_code) . '</pre></div>';
                } catch (Exception $e) {
                    echo '<div class="notice notice-error"><p>' . esc_html__('Code formatting failed: ', 'adversarial-code-generator') . esc_html($e->getMessage()) . '</p></div>';
                }
            }
            ?>
        </div>
        <?php
        return ob_get_clean();
    }

    public function code_translate_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-translate">
            <h2><?php esc_html_e('Code Translator', 'adversarial-code-generator'); ?></h2>
            <form method="post" class="code-translate-form">
                <?php wp_nonce_field('adversarial_code_translate', 'adversarial_nonce'); ?>
                <div class="form-group">
                    <label for="code_to_translate"><?php esc_html_e('Code to Translate:', 'adversarial-code-generator'); ?></label>
                    <div class="code-editor-wrapper code-to-translate" data-language="python" data-theme="monokai" style="height: 200px;"></div>
                    <input type="hidden" class="code-to-translate-value" name="code_to_translate_value" value="">
                </div>
                <div class="form-group">
                    <label for="source_language"><?php esc_html_e('Source Language:', 'adversarial-code-generator'); ?></label>
                    <select id="source_language" name="source_language" class="regular-text">
                        <option value="python" selected>Python</option>
                        <option value="javascript">JavaScript</option>
                        <option value="java">Java</option>
                        <option value="php">PHP</option>
                        <option value="cpp">C++</option>
                        <option value="csharp">C#</option>
                        <option value="go">Go</option>
                        <option value="ruby">Ruby</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="target_language"><?php esc_html_e('Target Language:', 'adversarial-code-generator'); ?></label>
                    <select id="target_language" name="target_language" class="regular-text">
                        <option value="python">Python</option>
                        <option value="javascript" selected>JavaScript</option>
                        <option value="java">Java</option>
                        <option value="php">PHP</option>
                        <option value="cpp">C++</option>
                        <option value="csharp">C#</option>
                        <option value="go">Go</option>
                        <option value="ruby">Ruby</option>
                    </select>
                </div>
                <button type="submit" class="button button-primary"><?php esc_html_e('Translate Code', 'adversarial-code-generator'); ?></button>
            </form>
            
            <?php
            if (isset($_POST['code_to_translate_value']) && wp_verify_nonce($_POST['adversarial_nonce'], 'adversarial_code_translate')) {
                try {
                    $code = sanitize_textarea_field($_POST['code_to_translate_value']);
                    $source_lang = isset($_POST['source_language']) ? sanitize_text_field($_POST['source_language']) : 'python';
                    $target_lang = isset($_POST['target_language']) ? sanitize_text_field($_POST['target_language']) : 'javascript';
                    
                    $translator = new TranslationSupport();
                    $translated_code = $translator->translate_code($code, $source_lang, $target_lang);
                    
                    echo '<div class="notice notice-success"><p>' . esc_html__('Code translated successfully!', 'adversarial-code-generator') . '</p></div>';
                    echo '<div class="translated-code"><pre>' . esc_html($translated_code) . '</pre></div>';
                } catch (Exception $e) {
                    echo '<div class="notice notice-error"><p>' . esc_html__('Code translation failed: ', 'adversarial-code-generator') . esc_html($e->getMessage()) . '</p></div>';
                }
            }
            ?>
        </div>
        <?php
        return ob_get_clean();
    }
}