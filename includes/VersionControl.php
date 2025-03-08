class VersionControl {
    private static $instance;
    private $versions_directory;
    
    private function __construct() {
        $upload_dir = wp_upload_dir();
        $this->versions_directory = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/versions';
        wp_mkdir_p($this->versions_directory);
    }
    
    public static function get_instance() {
        if (!self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    public function save_version($code, $prompt, $language) {
        $version_id = uniqid();
        $version_data = [
            'code' => $code,
            'prompt' => $prompt,
            'language' => $language,
            'created_at' => current_time('mysql')
        ];
        
        $version_file = $this->versions_directory . '/' . $version_id . '.json';
        file_put_contents($version_file, json_encode($version_data));
        
        return $version_id;
    }
    
    public function get_version($version_id) {
        $version_file = $this->versions_directory . '/' . $version_id . '.json';
        
        if (!file_exists($version_file)) {
            throw new Exception("Version not found");
        }
        
        return json_decode(file_get_contents($version_file), true);
    }
}