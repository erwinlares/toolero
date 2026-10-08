# Which paths are relative paths on the local file system

Internal helper. A value is *not* a relative local path when it is `NA`,
empty, absolute (including a leading `~`, and a Windows drive), or
prefixed with a URL scheme (`https://`, `s3://`): a URL is not a file
path at all, so it is never joined to the project root.

## Usage

``` r
.is_relative_local_path(path)
```

## Arguments

- path:

  Character vector.

## Value

A logical vector the length of `path`.
