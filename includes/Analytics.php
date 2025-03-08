class Analytics {
    private $wpdb;
    private $table_name;

    public function __construct() {
        global $wpdb;
        $this->wpdb = $wpdb;
        $this->table_name = $wpdb->prefix . 'adversarial_code_analytics';
    }

    public function install() {
        $charset_collate = $this->wpdb->get_charset_collate();
        
        $sql = "CREATE TABLE IF NOT EXISTS $this->table_name (
            id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            request_id bigint(20) unsigned NOT NULL,
            model_id varchar(50) NOT NULL,
            action varchar(20) NOT NULL,
            tokens_in int NOT NULL,
            tokens_out int NOT NULL,
            duration float NOT NULL,
            status varchar(20) NOT NULL,
            created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY  (id),
            KEY request_id (request_id),
            KEY model_id (model_id),
            KEY action (action),
            KEY created_at (created_at)
        ) $charset_collate;";

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';
        dbDelta($sql);
    }

    public function log_api_call($request_id, $model_id, $action, $tokens_in, $tokens_out, $duration, $status) {
        $this->wpdb->insert(
            $this->table_name,
            [
                'request_id' => $request_id,
                'model_id' => $model_id,
                'action' => $action,
                'tokens_in' => $tokens_in,
                'tokens_out' => $tokens_out,
                'duration' => $duration,
                'status' => $status
            ]
        );
    }

    public function get_usage_report($days = 30) {
        $date = date('Y-m-d H:i:s', strtotime("-$days days"));
        return $this->wpdb->get_results(
            $this->wpdb->prepare("
                SELECT model_id, action, COUNT(*) AS calls, 
                       SUM(tokens_in) AS tokens_in, SUM(tokens_out) AS tokens_out,
                       AVG(duration) AS avg_duration
                FROM $this->table_name
                WHERE created_at >= %s
                GROUP BY model_id, action
                ORDER BY calls DESC
            ", $date)
        );
    }
}