class Logger {
    private static $instance;
    private $log_file;

    private function __construct() {
        $upload_dir = wp_upload_dir();
        $this->log_file = $upload_dir['basedir'] . '/adversarial-code-generator/logs/' . date('Y-m-d') . '.log';
        wp_mkdir_p(dirname($this->log_file));
    }

    public static function get_instance() {
        if (!self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function info($message) {
        $this->log('INFO', $message);
    }

    public function warning($message) {
        $this->log('WARNING', $message);
    }

    public function error($message) {
        $this->log('ERROR', $message);
    }

    private function log($level, $message) {
        $timestamp = current_time('mysql');
        $log_entry = "$timestamp [$level] $message" . PHP_EOL;
        
        file_put_contents($this->log_file, $log_entry, FILE_APPEND);
        
        // Also send to WordPress error log
        if ($level === 'ERROR') {
            error_log("Adversarial Code Generator [$level]: $message");
        }
    }
}