class ActivityLogging {
    private $log_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->log_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/logs';
        wp_mkdir_p($this->log_dir);
        
        add_action('adversarial_code_generated', [$this, 'log_code_generation']);
        add_action('adversarial_code_executed', [$this, 'log_code_execution']);
        add_action('adversarial_code_shared', [$this, 'log_code_sharing']);
    }

    public function log_code_generation($prompt, $code, $language) {
        $this->write_log('generation', [
            'prompt' => $prompt,
            'code' => $code,
            'language' => $language,
            'user' => get_current_user_id(),
            'timestamp' => current_time('mysql')
        ]);
    }

    public function log_code_execution($code, $language, $output) {
        $this->write_log('execution', [
            'code' => $code,
            'language' => $language,
            'output' => $output,
            'user' => get_current_user_id(),
            'timestamp' => current_time('mysql')
        ]);
    }

    public function log_code_sharing($code_id, $email) {
        $this->write_log('sharing', [
            'code_id' => $code_id,
            'email' => $email,
            'user' => get_current_user_id(),
            'timestamp' => current_time('mysql')
        ]);
    }

    private function write_log($type, $data) {
        $filename = $this->log_dir . "/activity_{$type}_" . date('Ymd') . '.log';
        $log_entry = json_encode([
            'type' => $type,
            'data' => $data,
            'timestamp' => microtime(true)
        ]) . "\n";
        
        file_put_contents($filename, $log_entry, FILE_APPEND);
    }

    public function get_activity_logs($type = null, $limit = 100) {
        $log_files = glob($this->log_dir . '/activity_*.log');
        $logs = [];
        
        foreach ($log_files as $file) {
            $file_logs = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($file_logs as $line) {
                $log = json_decode($line, true);
                if ($log && (!$type || $log['type'] === $type)) {
                    $logs[] = $log;
                }
            }
        }
        
        usort($logs, function($a, $b) {
            return $b['timestamp'] - $a['timestamp'];
        });
        
        return array_slice($logs, 0, $limit);
    }
}