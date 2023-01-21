RSpec.describe ManageIQ::Floe::Workflow::ChoiceRule do
  describe "#true?" do
    let(:subject) { described_class.true?(payload, context) }

    context "Boolean Expression" do
      context "Not" do
        let(:payload) { {"Not" => {"Variable" => "$.foo", "StringEquals" => "bar"}, "Next" => "FirstMatchState"} }

        context "that is not equal to 'bar'" do
          let(:context) { {"foo" => "foo"} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is equal to 'bar'" do
          let(:context) { {"foo" => "bar"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "And" do
        let(:context) { {"foo" => "foo", "bar" => "bar"} }

        context "with all sub-choices being true" do
          let(:payload) { {"And" => [{"Variable" => "$.foo", "StringEquals" => "foo"}, {"Variable" => "$.bar", "StringEquals" => "bar"}], "Next" => "FirstMatchState"} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with one sub-choice false" do
          let(:payload) { {"And" => [{"Variable" => "$.foo", "StringEquals" => "foo"}, {"Variable" => "$.bar", "StringEquals" => "foo"}], "Next" => "FirstMatchState"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "Or" do
        let(:context) { {"foo" => "foo", "bar" => "bar"} }

        context "with one sub-choice being true" do
          let(:payload) { {"Or" => [{"Variable" => "$.foo", "StringEquals" => "foo"}, {"Variable" => "$.bar", "StringEquals" => "foo"}], "Next" => "FirstMatchState"} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with no sub-choices being true" do
          let(:payload) { {"Or" => [{"Variable" => "$.foo", "StringEquals" => "bar"}, {"Variable" => "$.bar", "StringEquals" => "foo"}], "Next" => "FirstMatchState"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context "Data-Test Expression" do
      context "with a missing variable" do
        let(:payload) { {"Variable" => "$.foo", "NumericEquals" => 1, "Next" => "FirstMatchState" } }
        let(:context) { {} }

        it "raises an exception" do
          expect { subject }.to raise_exception(RuntimeError, "No such variable [$.foo]")
        end
      end

      context "with IsNull" do
        let(:payload) { {"Variable" => "$.foo", "IsNull" => true} }

        context "with null" do
          let(:context) { {"foo" => nil} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with non-null" do
          let(:context) { {"foo" => "bar"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with IsPresent" do
        let(:payload) { {"Variable" => "$.foo", "IsPresent" => true} }

        context "with null" do
          let(:context) { {"foo" => nil} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end

        context "with non-null" do
          let(:context) { {"foo" => "bar"} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end
      end

      context "with IsNumeric" do
        let(:payload) { {"Variable" => "$.foo", "IsNumeric" => true} }

        context "with an integer" do
          let(:context) { {"foo" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with a float" do
          let(:context) { {"foo" => 1.5} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with a string" do
          let(:context) { {"foo" => "bar"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with IsString" do
        let(:payload) { {"Variable" => "$.foo", "IsString" => true} }

        context "with a string" do
          let(:context) { {"foo" => "bar"} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with a number" do
          let(:context) { {"foo" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with IsBoolean" do
        let(:payload) { {"Variable" => "$.foo", "IsBoolean" => true} }

        context "with a boolean" do
          let(:context) { {"foo" => true} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with a number" do
          let(:context) { {"foo" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with IsTimestamp" do
        let(:payload) { {"Variable" => "$.foo", "IsTimestamp" => true} }

        context "with a timestamp" do
          let(:context) { {"foo" => "2016-03-14T01:59:00Z"} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "with a number" do
          let(:context) { {"foo" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end

        context "with a string that isn't a date" do
          let(:context) { {"foo" => "bar"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end

        context "with a date that isn't in rfc3339 format" do
          let(:context) { {"foo" => "2023-01-21 16:30:32 UTC"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericEquals" do
        let(:payload) { {"Variable" => "$.foo", "NumericEquals" => 1, "Next" => "FirstMatchState" } }

        context "that equals the variable" do
          let(:context) { {"foo" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that does not equal the variable" do
          let(:context) { {"foo" => 2} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericEqualsPath" do
        let(:payload) { {"Variable" => "$.foo", "NumericEqualsPath" => "$.bar", "Next" => "FirstMatchState" } }

        context "that equals the variable" do
          let(:context) { {"foo" => 1, "bar" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that does not equal the variable" do
          let(:context) { {"foo" => 2, "bar" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericLessThan" do
        let(:payload) { {"Variable" => "$.foo", "NumericLessThan" => 1, "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 0} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericLessThanPath" do
        let(:payload) { {"Variable" => "$.foo", "NumericLessThanPath" => "$.bar", "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 0, "bar" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 1, "bar" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericGreaterThan" do
        let(:payload) { {"Variable" => "$.foo", "NumericGreaterThan" => 1, "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 2} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericGreaterThanPath" do
        let(:payload) { {"Variable" => "$.foo", "NumericGreaterThanPath" => "$.bar", "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 2, "bar" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 1, "bar" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericLessThanEquals" do
        let(:payload) { {"Variable" => "$.foo", "NumericLessThanEquals" => 1, "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 2} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericLessThanEqualsPath" do
        let(:payload) { {"Variable" => "$.foo", "NumericLessThanEqualsPath" => "$.bar", "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 1, "bar" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 2, "bar" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericGreaterThanEquals" do
        let(:payload) { {"Variable" => "$.foo", "NumericGreaterThanEquals" => 1, "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 0} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a NumericGreaterThanEqualsPath" do
        let(:payload) { {"Variable" => "$.foo", "NumericGreaterThanEqualsPath" => "$.bar", "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => 1, "bar" => 1} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => 0, "bar" => 1} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end

      context "with a StringMatches" do
        let(:payload) { {"Variable" => "$.foo", "StringMatches" => "*.log", "Next" => "FirstMatchState" } }

        context "that is true" do
          let(:context) { {"foo" => "audit.log"} }

          it "returns true" do
            expect(subject).to eq(true)
          end
        end

        context "that is false" do
          let(:context) { {"foo" => "audit"} }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end
    end
  end
end
