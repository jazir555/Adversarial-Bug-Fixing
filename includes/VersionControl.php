class VersionControl {
    private $versions_dir;

    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->versions_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/versions';
        wp_mkdir_p($this->versions_dir);
    }

    public function save_version($entry_id, $code, $message) {
        $version_data = [
            'entry_id' => $entry_id,
            'code' => $code,
            'message' => $message,
            'created_at' => current_time('mysql')
        ];
        
        $filename = $this->versions_dir . '/' . $entry_id . '_' . uniqid() . '.json';
        file_put_contents($filename, wp_json_encode($version_data));
    }

    public function get_versions($entry_id) {
        $versions = [];
        $files = glob($this->versions_dir . '/' . $entry_id . '_*.json');
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            $version_data = json_decode($content, true);
            if ($version_data && isset($version_data['entry_id']) && $version_data['entry_id'] == $entry_id) {
                $versions[] = $version_data;
            }
        }
        
        usort($versions, function($a, $b) {
            return strtotime($b['created_at']) - strtotime($a['created_at']);
        });
        
        return $versions;
    }
}