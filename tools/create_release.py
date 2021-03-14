#! /usr/bin/env python

"""Run this from the project root to create a new release."""

import click
import os
import os.path
import pathspec
import time
import zipfile


def load_gcloudignore():
    with open("src/.gcloudignore") as gcloudignore:
        return pathspec.PathSpec.from_lines(
            pathspec.patterns.GitWildMatchPattern, gcloudignore
        )


def create_zipfile(target):
    os.makedirs(os.path.dirname(target), exist_ok=True)
    gcloudignore = load_gcloudignore()
    with zipfile.ZipFile(target, mode="x") as z:
        for f in os.listdir("src"):
            if not gcloudignore.match_file(f):
                print("Zipping " + f)
                z.write("src/{}".format(f), arcname=f)
    print("Created ", target)


def upload_zipfile(target, bucket):
    os.system("gsutil cp -n {} gs://{}".format(target, bucket))


@click.command()
@click.option("-b", "--bucket", required=True, help="Bucket path to upload to.")
@click.option(
    "-v", "--version", default=time.strftime("%Y%m%d.%H%M%S"), help="Version name."
)
def create_release(bucket, version):
    """Creates a source code zip file and uploads it to gs bucket."""
    target = "build/src-{}.zip".format(version)
    create_zipfile(target)
    upload_zipfile(target, bucket)


if __name__ == "__main__":
    create_release()