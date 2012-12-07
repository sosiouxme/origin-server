module Console::ConsoleHelper

  def openshift_url(relative='')
    "https://#{`hostname`}/console/#{relative}"
  end

  def legal_opensource_disclaimer_url
    openshift_url 'legal/opensource_disclaimer'
  end

  def logout_path
    '/console/logout'
  end

  def outage_notification
  end

  def product_branding
    content_tag(:span,"", :class => 'brand-image')  << content_tag(:span, "<strong>Open</strong>Shift Enterprise".html_safe, :class => 'brand-text headline')
  end

  def product_title
    'OpenShift Enterprise by Red Hat'
  end
end
