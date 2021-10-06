# This file contains the configuration for Credo.
#
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
%{
  #
  # You can have as many configs as you like in the `configs:` field.
  configs: [
    %{
      #
      # Run any config using `mix credo -C <name>`. If no config name is given
      # "default" is used.
      name: "default",
      #
      # these are the files included in the analysis
      files: %{
        #
        # you can give explicit globs or simply directories
        # in the latter case `**/*.{ex,exs}` will be used
        included: ["lib/", "src/", "web/", "apps/", "config/"],
        excluded: ["apps/clever/lib/mix/tasks/remove_null_clever_entries.ex"]
      },
      #
      # The `checks:` field contains all the checks that are run. You can
      # customize the parameters of any given check by adding a second element
      # to the tuple.
      #
      # There are two ways of deactivating a check:
      # 1. deleting the check from this list
      # 2. putting `false` as second element (to quickly "comment it out"):
      #
      #      {Credo.Check.Consistency.ExceptionNames, false}
      #
      checks: [
        {Credo.Check.Consistency.ExceptionNames},
        {Credo.Check.Consistency.LineEndings},
        # MS - we get most warning from this with generated Phoenix files
        {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
        {Credo.Check.Consistency.SpaceAroundOperators},
        {Credo.Check.Consistency.SpaceInParentheses},
        {Credo.Check.Consistency.TabsOrSpaces},

        # For some checks, like AliasUsage, you can only customize the priority
        # Priority values are: `low, normal, high, higher`
        {Credo.Check.Design.AliasUsage, false},
        # For others you can set parameters
        # LN - 2016-09-27 - disable this for now, we are okay with duplicate code ... today
        {Credo.Check.Design.DuplicatedCode, false},

        # You can also customize the exit_status of each check.
        # If you don't want TODO comments to cause `mix credo` to fail, just
        # set this value to 0 (zero).
        {Credo.Check.Design.TagTODO, exit_status: 0},

        # Disabled for now, so FIXME tags can be added for future cleanup.
        {Credo.Check.Design.TagFIXME, false},
        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Readability.LargeNumbers, false},
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},
        {Credo.Check.Readability.ModuleAttributeNames},
        {Credo.Check.Readability.ModuleDoc, priority: :low},
        {Credo.Check.Readability.ModuleNames},
        {Credo.Check.Readability.ParenthesesInCondition},
        {Credo.Check.Readability.PredicateFunctionNames},
        {Credo.Check.Readability.Semicolons},
        {Credo.Check.Readability.TrailingBlankLine},
        {Credo.Check.Readability.TrailingWhiteSpace},
        {Credo.Check.Readability.VariableNames},
        {Credo.Check.Refactor.ABCSize},
        {Credo.Check.Refactor.CaseTrivialMatches},
        {Credo.Check.Refactor.CondStatements},
        {Credo.Check.Refactor.FunctionArity},
        # not valid from Elixir 1.8, generated noisy output
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Refactor.MatchInCondition},
        # permit a pipe chain to start with a "from" function (really meaning Ecto.Query.from)
        # or a "conn" function (really meaning Plug.Test.conn)
        # they're a common idiom in the code
        {Credo.Check.Refactor.PipeChainStart, excluded_functions: ["conn", "from"]},
        {Credo.Check.Refactor.CyclomaticComplexity},
        {Credo.Check.Refactor.NegatedConditionsInUnless},
        {Credo.Check.Refactor.NegatedConditionsWithElse},
        {Credo.Check.Refactor.Nesting},
        {Credo.Check.Refactor.UnlessWithElse},
        {Credo.Check.Warning.IExPry},
        {Credo.Check.Warning.IoInspect},
        # not valid from Elixir 1.8, generated noisy output
        {Credo.Check.Warning.LazyLogging, false},
        {Credo.Check.Warning.OperationOnSameValues},
        {Credo.Check.Warning.UnusedEnumOperation},
        {Credo.Check.Warning.UnusedKeywordOperation},
        {Credo.Check.Warning.UnusedListOperation},
        {Credo.Check.Warning.UnusedStringOperation},
        {Credo.Check.Warning.UnusedTupleOperation},
        {Credo.Check.Warning.OperationWithConstantResult}
      ]
    }
  ]
}
