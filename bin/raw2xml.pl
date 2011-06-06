#!/usr/bin/perl

use strict;
use warnings;

# read in a .raw ascii text file, output an ogre mesh xml file
# this is not actually needed now that we have an exporter that goes diectly from blender to ogre xml.

my $in_filename = shift;

if ( ! $in_filename )
{
    print "Usage: $0 inputfile\n";
    exit 1;
}

# read the input file
open( INFILE, $in_filename ) || die "couldn't open input file '$in_filename'\n";
my @input_lines = <INFILE>;
close( INFILE );

chomp( @input_lines );  # strip trailing newlines

# parse the input lines into a set of polys
my @faces;
my @vertices;
my %vertex_ids;

foreach my $line ( @input_lines )
{
    my @values = split( /\s+/, $line );
    if ( scalar( @values ) > 9 ) # if there are more than 3 vertices...
    {
        die "ogre does not support Quads in XML - please re-export as triangles-only.";
    }

    my (@v1, @v2, @v3 );
    my @face;

    @v1 = @values[0 .. 2];
    @v2 = @values[3 .. 5];
    @v3 = @values[6 .. 8];

    foreach my $vertex ( \@v1, \@v2, \@v3 )
    {
        my $vertex_name = join( "-", @$vertex );   # make an ID for the point
        my $vertex_id;
        # did it already exist in our vertex list?
        if ( defined( $vertex_ids{ $vertex_name } ) )
        {
            $vertex_id = $vertex_ids{ $vertex_name };
        }
        else
        {
            push @vertices, $vertex; 
            $vertex_id = $#vertices;
            $vertex_ids{ $vertex_name } = $vertex_id;   # store the id for this vertex
        }
        push @face, $vertex_id;
    }

    push @faces, \@face;
}



my $num_faces = scalar( @faces );
my $num_vertices = scalar( @vertices );

# output as XML!
print <<EOF;
<mesh>
    <submeshes>
        <submesh material="Mat01" usesharedvertices="false" use32bitindexes="false" operationtype="triangle_list">
            <faces count="$num_faces">
EOF

foreach my $face ( @faces )
{
    print <<EOF
                <face v1="$face->[0]" v2="$face->[1]" v3="$face->[2]" />
EOF
}

print <<EOF;
            </faces>
            <geometry vertexcount="$num_vertices">
                <vertexbuffer positions="true" normals="false" colours_diffuse="true">
EOF

foreach my $vertex ( @vertices )
{
    print <<EOF;
                    <vertex>
                        <position x="$vertex->[0]" y="$vertex->[1]" z="$vertex->[2]" />
                        <colour_diffuse value="1 1 1" />
                    </vertex>
EOF
}

print <<EOF;
                </vertexbuffer>
            </geometry>
        </submesh>
    </submeshes>
</mesh>
EOF

print "\n";

exit 0;

__END__
