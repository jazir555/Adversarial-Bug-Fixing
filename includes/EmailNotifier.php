class EmailNotifier {
    public function send_completion_notification($result) {
        $settings = Settings::get_instance();
        $notification_email = $settings->get('notification_email');
        
        if (!$notification_email) {
            return;
        }
        
        $subject = 'Code Generation Complete';
        $message = "Your code generation request has been completed.\n\n";
        $message .= "Iterations: {$result['iterations']}\n";
        $message .= "Duration: " . number_format($result['duration'], 2) . "s\n";
        
        if (isset($result['features_implemented'])) {
            $message .= "Features implemented: {$result['features_implemented']}\n";
        }
        
        wp_mail($notification_email, $subject, $message);
    }
    
    public function send_error_notification($error) {
        $settings = Settings::get_instance();
        $notification_email = $settings->get('notification_email');
        
        if (!$notification_email) {
            return;
        }
        
        $subject = 'Code Generation Error';
        $message = "An error occurred during code generation:\n\n";
        $message .= $error->getMessage();
        
        wp_mail($notification_email, $subject, $message);
    }
}