package SL;
use Mojo::Base 'Mojolicious';
use Data::Dumper;


sub startup {
    my $self = shift;

    $self->plugin('SL::Helpers');
    $self->plugin('I18N', no_header_detect => 1);
    
    $self->secrets(['ok3YeeSeGh5sighe']);
    
    my $r = $self->routes;

    my $auth = $r->under(
        '/' => sub {
            my $c = shift;

            # Get login name:
            my $url_login_name     = $c->param('login');
            my $session_login_name = $c->session('login_name');

            # Both undefined? There's nothing we can do here. 
            if (!defined $url_login_name && !defined $session_login_name) {
                $c->render(text => "No login name", status => 403);
                return undef;
            }

            # Otherwise: URL param is always stronger.
            if (defined $url_login_name) {
                $c->session('login_name' => $url_login_name);
            }
            
            my $login_name = $c->session('login_name');
            
            unless ( $self->logged_in($c, $login_name) ) {
                $c->render(text => "Not logged in", status => 403);
                return undef;
            }

            return 1;
        }
    );


    $auth ->get('/testing')   ->to('Testing#index');
    $auth ->get('/docs')      ->to('Docs#index');
    
    $auth ->any('/gobd')                ->to('GoBD#index');
    $auth ->get('/gobd/show/#filename') ->to('GoBD#show');
    $auth ->get('/gobd/download')       ->to('GoBD#download');


    # Here we get when called from menu.pl:
    $r->any(
        '/' => sub {
            my $c = shift;

            my ($run, $login);
            
            unless ($run =  $c->param('run')) {
                $c->render(text => "No run parameter", status => 400);
                return undef;
            }
            unless ($login =  $c->param('login')) {
                $c->render(text => "No login parameter", status => 400);
                return undef;
            }

            my $url = $c->url_for("/$run")->query(login => $login);
            $c->redirect_to($url);
        }
    );
}


sub logged_in {
    my $self = shift;

    my ($controller, $username) = @_;

    my $cookies = $controller->req->cookies;

    my $user_has_cookie = 0;

    foreach (@$cookies) {
        if ($_->name eq "SL-$username") {
            $user_has_cookie = 1;
            last;
        }
    }

    return $user_has_cookie || 1;  # TODO: weg!
}


1;
