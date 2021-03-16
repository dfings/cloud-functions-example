#! /usr/bin/env python

"""Run this from the project root to create a new release."""

from itertools import filterfalse
import os
import os.path
import time
import zipfile

import click
import pathspec


def load_gcloudignore():
    with open("src/.gcloudignore") as gcloudignore:
        return pathspec.PathSpec.from_lines(
            pathspec.patterns.GitWildMatchPattern, gcloudignore
        )


def create_zipfile(target):
    os.makedirs(os.path.dirname(target), exist_ok=True)
    gcloudignore = load_gcloudignore()
    with zipfile.ZipFile(target, mode="x") as z:
        for file in filterfalse(gcloudignore.match_file, os.listdir("src")):
            print(f"Zipping {file}")
            z.write(f"src/{file}", arcname=file)
    print(f"Created {target}")


def upload_zipfile(target, bucket):
    os.system(f"gsutil cp -n {target} gs://{bucket}")


@click.command()
@click.option("-b", "--bucket", required=True, help="Bucket path to upload to.")
@click.option(
    "-v", "--version", default=time.strftime("%Y%m%d.%H%M%S"), help="Version name."
)
def create_release(bucket, version):
    """Creates a source code zip file and uploads it to gs bucket."""
    target = f"build/src-{version}.zip"
    create_zipfile(target)
    upload_zipfile(target, bucket)


if __name__ == "__main__":
    create_release()