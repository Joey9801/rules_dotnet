load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    "dotnet_context",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:common.bzl",
    "sets"
)


def _core_import_library_impl(ctx):
  """core_import_library_impl emits actions for importing an external dll (for example provided by nuget)."""
  dotnet = dotnet_context(ctx)
  name = ctx.label.name
 
  # Handle case of empty toolchain on linux and darwin
  if dotnet.library == None:
    library = dotnet.new_library(dotnet = dotnet)
    return [library]

  deps = ctx.attr.deps
  src = ctx.attr.src

  transitive = depset(direct = deps, transitive = [d[DotnetLibrary].transitive for d in deps])

  library = dotnet.new_library(
    dotnet = dotnet, 
    name = name, 
    deps = deps, 
    transitive = transitive,
    result = src.files.to_list()[0])

  transitive_files = [d[DotnetLibrary].result for d in library.transitive.to_list()]

  return [
      library,
      DefaultInfo(
          files = depset([library.result]),
          runfiles = ctx.runfiles(files = [dotnet.stdlib, library.result], transitive_files=depset(direct=transitive_files)),
      ),
  ]
  
core_import_library = rule(
    _core_import_library_impl,
    attrs = {
        "deps": attr.label_list(providers=[DotnetLibrary]),
        "src": attr.label(allow_files = FileType([".dll", ".exe"]), mandatory=True),        
        "_dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:core_context_data"))
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain_core"],
    executable = False,
)
