
  (function ($) {
  
  "use strict";

    // MENU
    $('.navbar-collapse a').on('click',function(){
      $(".navbar-collapse").collapse('hide');
    });
    
    // CUSTOM LINK
    $('.smoothscroll').click(function(){
      var el = $(this).attr('href');
      var elWrapped = $(el);
      var header_height = $('.navbar').height();
  
      scrollToDiv(elWrapped,header_height);
      return false;
  
      function scrollToDiv(element,navheight){
        var offset = element.offset();
        var offsetTop = offset.top;
        var totalScroll = offsetTop-navheight;
  
        $('body,html').animate({
        scrollTop: totalScroll
        }, 300);
      }
    });

    // =====================================================
    // LEAD CAPTURE FORM SUBMISSION
    // Sends lead data to API Gateway -> Lambda -> DynamoDB + SES
    // =====================================================
    var API_URL = "https://vy9tzepi9f.execute-api.ap-southeast-1.amazonaws.com/leads";

    $('#lead-capture-form').on('submit', function(e) {
      e.preventDefault(); // Stop the form from doing a normal page reload

      var name  = $('#ebook-form-name').val().trim();
      var email = $('#ebook-email').val().trim();
      var $btn  = $('#submit-btn');
      var $msg  = $('#form-message');

      // Disable button to prevent double-clicks
      $btn.prop('disabled', true).text('Submitting...');

      // Send data to API Gateway via AJAX (fetch)
      $.ajax({
        url: API_URL,
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
          name: name,
          email: email,
          message: "Requested ebook download"
        }),
        success: function(response) {
          // Show success message
          $msg.css({
            'display': 'block',
            'color': '#198754',
            'font-weight': 'bold'
          }).text('✅ Thank you, ' + name + '! Check your email for the ebook.');

          // Reset form fields
          $('#lead-capture-form')[0].reset();

          // Re-enable button
          $btn.prop('disabled', false).text('Download ebook');
        },
        error: function(xhr) {
          // Show error message
          var errorMsg = 'Something went wrong. Please try again.';
          try {
            var resp = JSON.parse(xhr.responseText);
            if (resp.error) errorMsg = resp.error;
          } catch(e) {}

          $msg.css({
            'display': 'block',
            'color': '#dc3545',
            'font-weight': 'bold'
          }).text('❌ ' + errorMsg);

          // Re-enable button
          $btn.prop('disabled', false).text('Download ebook');
        }
      });
    });
  
  })(window.jQuery);

