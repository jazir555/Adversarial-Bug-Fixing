class CodeTemplates {
    public function __construct() {
        add_shortcode('adversarial_code_template_library', [$this, 'template_library_shortcode']);
    }

    public function template_library_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-template-library">
            <h2><?php esc_html_e('Code Template Library', 'adversarial-code-generator'); ?></h2>
            <div class="template-search">
                <input type="text" id="template-search-input" placeholder="<?php esc_attr_e('Search templates...', 'adversarial-code-generator'); ?>">
                <button id="template-search-button" class="button"><?php esc_html_e('Search', 'adversarial-code-generator'); ?></button>
            </div>
            <div class="template-categories">
                <button data-category="all" class="button category-filter active"><?php esc_html_e('All', 'adversarial-code-generator'); ?></button>
                <button data-category="python" class="button category-filter"><?php esc_html_e('Python', 'adversarial-code-generator'); ?></button>
                <button data-category="javascript" class="button category-filter"><?php esc_html_e('JavaScript', 'adversarial-code-generator'); ?></button>
                <button data-category="java" class="button category-filter"><?php esc_html_e('Java', 'adversarial-code-generator'); ?></button>
                <button data-category="php" class="button category-filter"><?php esc_html_e('PHP', 'adversarial-code-generator'); ?></button>
            </div>
            <div class="templates-grid">
                <?php $this->display_templates(); ?>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }

    private function display_templates() {
        $templates = $this->get_templates();
        
        foreach ($templates as $template) {
            ?>
            <div class="template-card" data-language="<?php echo esc_attr($template['language']); ?>">
                <h3><?php echo esc_html($template['name']); ?></h3>
                <p class="template-description"><?php echo esc_html($template['description']); ?></p>
                <p class="template-language"><?php printf(__('Language: %s', 'adversarial-code-generator'), esc_html($template['language'])); ?></p>
                <div class="template-actions">
                    <button class="button button-primary view-template" data-id="<?php echo esc_attr($template['id']); ?>">
                        <?php esc_html_e('View', 'adversarial-code-generator'); ?>
                    </button>
                    <button class="button use-template" data-id="<?php echo esc_attr($template['id']); ?>">
                        <?php esc_html_e('Use Template', 'adversarial-code-generator'); ?>
                    </button>
                </div>
            </div>
            <?php
        }
    }

    private function get_templates() {
        $upload_dir = wp_upload_dir();
        $templates_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/templates';
        
        $templates = [];
        if (file_exists($templates_dir)) {
            foreach (glob("$templates_dir/*.json") as $file) {
                $data = json_decode(file_get_contents($file), true);
                if ($data) {
                    $templates[] = [
                        'id' => basename($file, '.json'),
                        'name' => $data['name'],
                        'description' => $data['description'],
                        'code' => $data['code'],
                        'language' => $data['language'],
                        'date_created' => $data['date_created']
                    ];
                }
            }
        }
        
        return $templates;
    }
}