RSpec.describe "exe/floe", :slow => true do
  include AwesomeSpawn::SpecHelper
  before { enable_spawning }

  let(:exe)      { File.expand_path("../../exe/floe", __dir__) }
  let(:workflow) { File.expand_path("data/workflow.asl", __dir__) }

  it "displays help" do
    output = AwesomeSpawn.run!(exe, :params => [:help]).output
    lines = output.lines(:chomp => true)

    expect(lines).to start_with("Usage: floe [options] workflow input [workflow2 input2]")
    expect(lines).to include("v#{Floe::VERSION}")

    # it should also include options from runners
    expect(lines).to include("Container runner options:")
  end

  it "with no parameters" do
    result = AwesomeSpawn.run(exe)
    expect(result).to be_failure

    lines = result.error.lines(:chomp => true)
    expect(lines.first).to eq("Error: workflow/input pairs must be specified.")
  end

  it "with a bare workflow and no input" do
    output = AwesomeSpawn.run!(exe, :params => [workflow]).output
    lines = output.lines(:chomp => true)

    expect(lines.first).to include("checking 1 workflows...")
    expect(lines.last).to eq("{}")
  end

  it "with a bare workflow and input" do
    output = AwesomeSpawn.run!(exe, :params => [workflow, '{"foo":1}']).output
    lines = output.lines(:chomp => true)

    expect(lines.first).to include("checking 1 workflows...")
    expect(lines.last).to eq('{"foo"=>1}')
  end

  it "with a bare workflow and --input" do
    output = AwesomeSpawn.run!(exe, :params => [workflow, {:input => '{"foo":1}'}]).output
    lines = output.lines(:chomp => true)

    expect(lines.first).to include("checking 1 workflows...")
    expect(lines.last).to eq('{"foo"=>1}')
  end

  it "with --workflow and no input" do
    output = AwesomeSpawn.run!(exe, :params => {:workflow => workflow}).output
    lines = output.lines(:chomp => true)

    expect(lines.first).to include("checking 1 workflows...")
    expect(lines.last).to eq("{}")
  end

  it "with --workflow and --input" do
    output = AwesomeSpawn.run!(exe, :params => {:workflow => workflow, :input => '{"foo":1}'}).output
    lines = output.lines(:chomp => true)

    expect(lines.first).to include("checking 1 workflows...")
    expect(lines.last).to eq('{"foo"=>1}')
  end

  it "with a bare workflow and --workflow" do
    result = AwesomeSpawn.run(exe, :params => [workflow, {:workflow => workflow}])
    expect(result).to be_failure

    lines = result.error.lines(:chomp => true)
    expect(lines.first).to eq("Error: cannot specify both --workflow and bare workflows.")
  end

  it "with --input but no workflows" do
    result = AwesomeSpawn.run(exe, :params => {:input => '{"foo":1}'})
    expect(result).to be_failure

    lines = result.error.lines(:chomp => true)
    expect(lines.first).to eq("Error: workflow(s) must be specified.")
  end

  it "with multiple bare workflow/input pairs" do
    output = AwesomeSpawn.run!(exe, :params => [workflow, '{"foo":1}', workflow, '{"foo":2}']).output
    lines = output.lines(:chomp => true)

    expect(lines.first).to include("checking 2 workflows...")
    expect(lines.last(7).join("\n")).to eq(<<~OUTPUT.chomp)
      workflow
      ===
      {"foo"=>1}

      workflow
      ===
      {"foo"=>2}
    OUTPUT
  end

  it "with multiple bare workflows and --input" do
    output = AwesomeSpawn.run!(exe, :params => [workflow, workflow, {:input => '{"foo":1}'}]).output
    lines = output.lines(:chomp => true)

    expect(lines.first).to include("checking 2 workflows...")
    expect(lines.last(7).join("\n")).to eq(<<~OUTPUT.chomp)
      workflow
      ===
      {"foo"=>1}

      workflow
      ===
      {"foo"=>1}
    OUTPUT
  end

  it "with mismatched workflow/input pairs" do
    result = AwesomeSpawn.run(exe, :params => [workflow, workflow, '{"foo":2}'])
    expect(result).to be_failure

    lines = result.error.lines(:chomp => true)
    expect(lines.first).to eq("Error: workflow/input pairs must be specified.")
  end
end
