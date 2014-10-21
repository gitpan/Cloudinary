package Mojolicious::Plugin::Cloudinary;

=head1 NAME

Mojolicious::Plugin::Cloudinary - Talk with cloudinary.com

=head1 DESCRIPTION

This register the methods from the L<Cloudinary> module as helpers in
your L<Mojolicious> web application. See L</HELPERS> for details.

=head1 SYNOPSIS

    package MyWebApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;
        $self->plugin('Mojolicious::Plugin::Cloudinary', {
            cloud_name => $str,
            api_key => $str,
            api_secret => $str,
        });
    }

    package MyWebApp::SomeController;

    sub upload {
        my $self = shift;

        $self->render_later;
        $self->cloudinary_upload({
            file => $self->param('upload_param'),
            on_success => sub {
                my $res = shift;
                $self->render_json($res);
            },
            on_error => sub {
                my $res = shift || { error => 'Unknown' };
                $self->render_json($res);
            },
        });
    }

=cut

use Mojo::Base -base;
use File::Basename;
use Mojo::UserAgent;
use Mojo::Util qw/ sha1_sum url_escape /;
use Scalar::Util 'weaken';
use base qw/ Cloudinary Mojolicious::Plugin /;

our $VERSION = $Cloudinary::VERSION;

=head1 ATTRIBUTES

=head2 js_image

This string will be used as the image src for images constructed by
L</cloudinary_js_image>. The default is "/image/blank.png".

=cut

__PACKAGE__->attr(js_image => sub { '/image/blank.png' });

=head1 HELPERS

=head2 cloudinary_upload

See L<Cloudinary/upload>.

=head2 cloudinary_destroy

See L<Cloudinary/destroy>.

=head2 cloudinary_url_for

See L<Cloudinary/url_for>.

=head2 cloudinary_image

    $str = $c->cloudinary_image($public_id, $url_for_args, $image_args);

This will use L<Mojolicious::Plugin::TagHelpers/image> to create an image
tag where "src" is set to a cloudinary image. C<$url_for_args> are passed
on to L</url_for> and C<$image_args> are passed on to
L<Mojolicious::Plugin::TagHelpers/image>.

=head2 cloudinary_js_image

    $str = $c->cloudinary_js_image($public_id, $url_for_args);

About the same as L</cloudinary_image>, except it creates an image which can
handled by the cloudinary jQuery plugin which you can read more about here:
L<http://cloudinary.com/blog/cloudinary_s_jquery_library_for_embedding_and_transforming_images>

Example usage:

    $c->cloudinary_js_image(1234567890 => {
        width => 115,
        height => 115,
        crop => 'thumb',
        gravity => 'faces',
        radius => '20',
    });

...will produce:

    <img src="/image/blank.png"
        class="cloudinary-js-image"
        alt="1234567890"
        data-src="1234567890"
        data-width="115"
        data-height="135"
        data-crop="thumb"
        data-gravity="faces"
        data-radius="20">

Note: The "class" and "alt" attributes are fixed for now.

=head1 METHODS

=head2 register

Will register the L</HELPERS> in the L<Mojolicious> application.

=cut

sub register {
    my($self, $app, $config) = @_;

    for my $k (keys %{ $config || {} }) {
        $self->$k($config->{$k}) if exists $config->{$k};
    }

    $app->helper(cloudinary_upload => sub {
        my $c = shift;
        $self->upload(@_);
    });
    $app->helper(cloudinary_destroy => sub {
        my $c = shift;
        $self->destroy(@_);
    });
    $app->helper(cloudinary_url_for => sub {
        my($c, $public_id, $args) = @_;
        my $scheme = $c->req->url->scheme || '';

        if(not defined $args->{'secure'} and $scheme eq 'https') {
            $args->{'secure'} = 1;
        }

        return $self->url_for($public_id, $args);
    });
    $app->helper(cloudinary_image => sub {
        my($c, $public_id, $args, $image_args) = @_;
        my $scheme = $c->req->url->scheme || '';

        if(not defined $args->{'secure'} and $scheme eq 'https') {
            $args->{'secure'} = 1;
        }

        return $c->image($self->url_for($public_id, $args), alt => $public_id, %$image_args);
    });
    $app->helper(cloudinary_js_image => sub {
        my($c, $public_id, $args) = @_;
        my $scheme = $c->req->url->scheme || '';

        if(not defined $args->{'secure'} and $scheme eq 'https') {
            $args->{'secure'} = 1;
        }

        return $c->image(
            $self->js_image,
            'alt' => $public_id,
            'class' => 'cloudinary-js-image',
            'data-src' => $public_id,
            map {
                my $k = $Cloudinary::LONGER{$_} || $_;
                ("data-$k" => $args->{$_})
            } keys %$args
        );
    });
}

=head1 COPYRIGHT & LICENSE

See L<Cloudinary>.

=head1 AUTHOR

Jan Henning Thorsen - jhthorsen@cpan.org

=cut

1;
