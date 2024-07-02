require "parslet"

module Floe
  class Workflow
    module IntrinsicFunction
      class Parser < Parslet::Parser
        rule(:spaces)  { str(' ').repeat(1) }
        rule(:spaces?) { spaces.maybe }
        rule(:digit)   { match('[0-9]') }
        rule(:quote)   { str('\'') }

        rule(:comma_sep) { str(',') >> spaces? }

        rule(:true_literal)  { str('true').as(:true_literal) }
        rule(:false_literal) { str('false').as(:false_literal) }
        rule(:null_literal)  { str('null').as(:null_literal) }

        rule(:number) do
          (
            str('-').maybe >> (
              str('0') | (match('[1-9]') >> digit.repeat)
            ) >> (
              str('.') >> digit.repeat(1)
            ).maybe >> (
              match('[eE]') >> (str('+') | str('-')).maybe >> digit.repeat(1)
            ).maybe
          ).as(:number)
        end

        rule(:string) do
          quote >> (
            (str('\\') >> any) | (quote.absent? >> any)
          ).repeat.as(:string) >> quote
        end

        rule(:jsonpath) do
          (
            str('$') >> match('[^,)]').repeat(1)
          ).as(:jsonpath)
        end

        rule(:arg) do
          string | number | jsonpath | true_literal | false_literal | null_literal | expression
        end

        rule(:args) { arg >> (comma_sep >> arg).repeat }

        rule(:states_array) do
          (
            str("States.Array") >> str('(') >> args >> str(')')
          ).as(:states_array)
        end

        rule(:states_uuid) do
          str("States.UUID()").as(:states_uuid)
        end

        rule(:expression) { states_array | states_uuid }
        root(:expression)
      end
    end
  end
end
