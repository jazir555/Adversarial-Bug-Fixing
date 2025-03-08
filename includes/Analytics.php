class Analytics {
    private $wpdb;
    private $table_name;
    
    public function __construct() {
        global $wpdb;
        $this->wpdb = $wpdb;
        $this->table_name = $wpdb->prefix . 'adversarial_code_analytics';
        
        add_action('adversarial_log_activity', [$this, 'log_activity']);
    }
    
    public function install() {
        $charset_collate = $this->wpdb->get_charset_collate();
        
        $sql = "CREATE TABLE IF NOT EXISTS $this->table_name (
            id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            user_id bigint(20) unsigned NOT NULL,
            activity_type varchar(50) NOT NULL,
            details longtext,
            created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY  (id),
            KEY user_id (user_id),
            KEY activity_type (activity_type),
            KEY created_at (created_at)
        ) $charset_collate;";
        
        require_once ABSPATH . 'wp-admin/includes/upgrade.php';
        dbDelta($sql);
    }
    
    public function log_activity($activity_type, $details = '') {
        $user_id = get_current_user_id();
        
        $this->wpdb->insert(
            $this->table_name,
            [
                'user_id' => $user_id,
                'activity_type' => $activity_type,
                'details' => $details
            ]
        );
    }
    
    public function get_activity_report($days = 30, $user_id = null) {
        $date = date('Y-m-d H:i:s', strtotime("-$days days"));
        
        $query = "SELECT activity_type, COUNT(*) AS count FROM $this->table_name";
        $args = [];
        
        if ($user_id !== null) {
            $query .= $this->wpdb->prepare(" WHERE user_id = %d", $user_id);
            $args[] = $user_id;
        } else {
            $query .= " WHERE created_at >= %s";
            $args[] = $date;
        }
        
        $query .= " GROUP BY activity_type ORDER BY count DESC";
        
        return $this->wpdb->get_results($this->wpdb->prepare($query, $args));
    }
    
    public function get_user_stats($user_id, $days = 30) {
        $date = date('Y-m-d H:i:s', strtotime("-$days days"));
        
        return $this->wpdb->get_row($this->wpdb->prepare("
            SELECT 
                COUNT(*) AS total_activities,
                SUM(CASE WHEN activity_type = 'code_generation' THEN 1 ELSE 0 END) AS code_generations,
                SUM(CASE WHEN activity_type = 'code_execution' THEN 1 ELSE 0 END) AS code_executions,
                SUM(CASE WHEN activity_type = 'code_sharing' THEN 1 ELSE 0 END) AS code_sharings
            FROM $this->table_name
            WHERE user_id = %d AND created_at >= %s
        ", $user_id, $date));
    }
}