#!/usr/bin/env dash

set -x
set -e
set -v

filename=$(basename $(printf "%s" $MODEL_URL | cut -d '/' -f3-))

dir='/mnt/llama.cpp'
lockfile="$dir/dl.lock"

while test -f lockfile
do
  sleep 99
done

start() {
  sha256="`shasum -a 256 "$dir/$filename" | awk '{print $1}'`"
  if test "$sha256" = "$MODEL_SHA256"
  then
    llama-server -m "$dir/$filename"
  else
    printf "%s\n" "Failed checksum"
  fi
}

if test -f "$dir/$filename"
then
  start
else
  printf "%s\n" "Locking and downloading..."
  touch $lockfile
  curl -L --output "$dir/$filename" "$MODEL_URL"
  rm $lockfile
  start
fi

