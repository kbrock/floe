RSpec.describe Floe::Workflow do
  let(:workflow) { described_class.load(GEM_ROOT.join("examples/workflow.asl")) }

  it "#to_dot" do
    expect(workflow.to_dot).to eq <<~DOT
      digraph {
        FirstState
        ChoiceState [ shape=diamond ]
        FirstMatchState
        SecondMatchState
        PassState
        FailState [ style=bold color=red ]
        SuccessState [ style=bold color=green ]
        NextState [ style=bold ]

        FirstState -> ChoiceState
        ChoiceState -> FirstMatchState [ label="$.foo == 1" ]
        ChoiceState -> SecondMatchState [ label="$.foo == 2" ]
        ChoiceState -> SuccessState [ label="$.foo == 3" ]
        ChoiceState -> FailState [ label="Default" ]
        FirstMatchState -> PassState
        SecondMatchState -> NextState
        PassState -> NextState
      }
    DOT
  end

  describe "#to_svg" do
    let(:svg) { Pathname.new("/tmp/workflow.svg") }

    before { svg.delete if svg.exist? }

    it "writes to a path if given" do
      expect(workflow.to_svg(path: svg)).to match(/^<svg/)
      expect(svg).to exist
      expect(svg.read).to match(/^<svg/)
    end

    it "returns the svg" do
      expect(workflow.to_svg).to match(/^<svg/)
      expect(svg).to_not exist
    end
  end
end
