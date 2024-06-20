RSpec.describe "exe/floe", :slow => true do
  include AwesomeSpawn::SpecHelper
  before { enable_spawning }

  let(:exe) { File.expand_path("../../exe/floe", __dir__) }

  it "displays help" do
    output = AwesomeSpawn.run!(exe, :params => [:help]).output
    lines = output.lines(:chomp => true)

    expect(lines).to start_with("Usage: floe [options] workflow input [workflow2 input2]")
    expect(lines).to include("v#{Floe::VERSION}")

    # it should also include options from runners
    expect(lines).to include("Container runner options:")
  end
end
