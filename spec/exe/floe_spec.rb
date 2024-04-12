RSpec.describe "exe/floe" do
  include AwesomeSpawn::SpecHelper
  before { enable_spawning }

  it "displays help" do
    output = AwesomeSpawn.run!("exe/floe --help").output

    expect(output).to start_with("Usage: floe [options] workflow input [workflow2 input2]")
    expect(output).to include(Floe::VERSION)

    # it should also include options from runners
    expect(output).to include("Container runner options:")
  end
end
