class AdvancedAnalytics {
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
            user_id bigint(20) unsigned NOT NULL,
            created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY  (id),
            KEY request_id (request_id),
            KEY model_id (model_id),
            KEY action (action),
            KEY created_at (created_at),
            KEY user_id (user_id)
        ) $charset_collate;";

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';
        dbDelta($sql);
    }

    public function log_api_call($request_id, $model_id, $action, $tokens_in, $tokens_out, $duration, $status, $user_id) {
        $this->wpdb->insert(
            $this->table_name,
            [
                'request_id' => $request_id,
                'model_id' => $model_id,
                'action' => $action,
                'tokens_in' => $tokens_in,
                'tokens_out' => $tokens_out,
                'duration' => $duration,
                'status' => $status,
                'user_id' => $user_id
            ]
        );
    }

    public function get_usage_report($days = 30, $user_id = null) {
        $date = date('Y-m-d H:i:s', strtotime("-$days days"));
        $query = "SELECT model_id, action, COUNT(*) AS calls, 
                         SUM(tokens_in) AS tokens_in, SUM(tokens_out) AS tokens_out,
                         AVG(duration) AS avg_duration
                  FROM $this->table_name";
        
        $args = [];
        
        if ($user_id !== null) {
            $query .= $this->wpdb->prepare(" WHERE user_id = %d", $user_id);
            $args[] = $user_id;
        } else {
            $query .= " WHERE created_at >= %s";
            $args[] = $date;
        }
        
        $query .= " GROUP BY model_id, action ORDER BY calls DESC";
        
        return $this->wpdb->get_results($this->wpdb->prepare($query, $args));
    }

    public function get_user_stats($user_id, $days = 30) {
        $date = date('Y-m-d H:i:s', strtotime("-$days days"));
        return $this->wpdb->get_row($this->wpdb->prepare("
            SELECT COUNT(*) AS total_requests, 
                   SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS successful_requests,
                   SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_requests,
                   AVG(duration) AS average_duration
            FROM $this->table_name
            WHERE user_id = %d AND created_at >= %s
        ", $user_id, $date));
    }
}