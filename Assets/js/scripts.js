jQuery(document).ready(function($) {
    $('.adversarial-generator-form').submit(function(e) {
        e.preventDefault();
        
        var form = $(this);
        var button = form.find('button[type="submit"]');
        var originalText = button.text();
        
        // Show loading indicator
        form.find('.loading-indicator').show();
        form.find('.results-container, .error-container').hide();
        
        $.ajax({
            type: 'POST',
            url: form.attr('action'),
            data: form.serialize(),
            success: function(response) {
                form.find('.loading-indicator').hide();
                
                // Check if response contains error
                if (response.indexOf('notice-error') !== -1) {
                    form.find('.error-container p').html($(response).find('.notice-error p').html());
                    form.find('.error-container').show();
                } else {
                    // Extract code and stats from response
                    var code = $(response).find('.generated-code pre code').html();
                    var iterations = $(response).find('.iterations').html();
                    var duration = $(response).find('.duration').html();
                    var featuresImplemented = $(response).find('.features-implemented').html();
                    var totalFeatures = $(response).find('.total-features').html();
                    
                    // Update results container
                    form.find('.results-container .generated-code code').html(code);
                    form.find('.results-container .iterations').html(iterations);
                    form.find('.results-container .duration').html(duration);
                    form.find('.results-container .features-implemented').html(featuresImplemented || 0);
                    form.find('.results-container .total-features').html(totalFeatures || 0);
                    
                    form.find('.results-container').show();
                }
                
                button.text(originalText);
            },
            error: function(xhr, status, error) {
                form.find('.loading-indicator').hide();
                form.find('.error-container p').html('Error generating code: ' + error);
                form.find('.error-container').show();
                button.text(originalText);
            }
        });
    });
    
    // Add code highlighting
    Prism.highlightAll();
});