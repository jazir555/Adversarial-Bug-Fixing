class HelpDocumentation {
    public function get_help_content($topic) {
        $help_topics = [
            'getting_started' => [
                'title' => 'Getting Started',
                'content' => '
                    <h3>Getting Started with Adversarial Code Generator</h3>
                    <p>Welcome to the Adversarial Code Generator! This plugin allows you to generate high-quality code using multiple AI models through an adversarial testing process.</p>
                    <h4>How to Use:</h4>
                    <ol>
                        <li>Enter your code generation request in the text area</li>
                        <li>Optionally add additional features you want to be implemented</li>
                        <li>Select the programming language</li>
                        <li>Click "Generate Code"</li>
                    </ol>
                    <h4>Example Requests:</h4>
                    <ul>
                        <li>"Build a Python function to calculate Fibonacci numbers"</li>
                        <li>"Create a JavaScript class for managing user sessions"</li>
                        <li>"Generate a PHP script to connect to a MySQL database"</li>
                    </ul>
                '
            ],
            'features' => [
                'title' => 'Features',
                'content' => '
                    <h3>Key Features</h3>
                    <ul>
                        <li>Adversarial code generation with multiple AI models</li>
                        <li>Iterative bug fixing and code refinement</li>
                        <li>Support for multiple programming languages</li>
                        <li>Version control for generated code</li>
                        <li>Detailed analytics and reporting</li>
                        <li>Sandboxed code execution environment</li>
                    </ul>
                    <h4>Advanced Features:</h4>
                    <ul>
                        <li>Customizable model rotation strategies</li>
                        <li>Rate limiting and API management</li>
                        <li>Security scanning of generated code</li>
                        <li>Comprehensive logging and monitoring</li>
                    </ul>
                '
            ],
            'troubleshooting' => [
                'title' => 'Troubleshooting',
                'content' => '
                    <h3>Troubleshooting Common Issues</h3>
                    <h4>API Errors:</h4>
                    <ul>
                        <li>Check your API keys in the settings</li>
                        <li>Verify your internet connection</li>
                        <li>Check if the API service is available</li>
                    </ul>
                    <h4>Code Generation Failures:</h4>
                    <ul>
                        <li>Try rephrasing your request</li>
                        <li>Be more specific about what you need</li>
                        <li>Check the error messages for details</li>
                    </ul>
                    <h4>Performance Issues:</h4>
                    <ul>
                        <li>Consider reducing the complexity of your request</li>
                        <li>Check your server resources</li>
                        <li>Review the analytics for performance bottlenecks</li>
                    </ul>
                '
            ]
        ];
        
        return isset($help_topics[$topic]) ? $help_topics[$topic] : [
            'title' => 'Help Documentation',
            'content' => '
                <h3>Help Documentation</h3>
                <p>Select a topic from the left menu to view detailed information.</p>
                <ul>
                    <li><a href="' . esc_url(add_query_arg('help_topic', 'getting_started')) . '">Getting Started</a></li>
                    <li><a href="' . esc_url(add_query_arg('help_topic', 'features')) . '">Features</a></li>
                    <li><a href="' . esc_url(add_query_arg('help_topic', 'troubleshooting')) . '">Troubleshooting</a></li>
                </ul>
            '
        ];
    }
}