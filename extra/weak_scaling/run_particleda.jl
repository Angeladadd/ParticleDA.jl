using ParticleDA
using TimerOutputs
using MPI

# Initialise MPI
MPI.Init()
mpi_size = MPI.Comm_size(MPI.COMM_WORLD)

# Include the sample model source code and load it
llw2d_src = joinpath(dirname(pathof(ParticleDA)), "..", "test", "models", "llw2d.jl")
include(llw2d_src)
using .LLW2d

observation_file = "test_observations.h5"
parameters_file = "parametersW1.yaml"
output_file = "llw2d_filtering.h5"
filter_type = OptimalFilter
summary_stat_type = NaiveMeanSummaryStat

my_rank = MPI.Comm_rank(MPI.COMM_WORLD)

if my_rank == 0 && !isfile(observation_file)
    observation_sequence = simulate_observations_from_model(
      LLW2d.init, parameters_file, observation_file
    )
end
if my_rank == 0 && isfile(output_file)
    rm(output_file)
end

MPI.Barrier(MPI.COMM_WORLD)

TimerOutputs.enable_debug_timings(ParticleDA)

final_states, final_statistics = run_particle_filter(
  LLW2d.init, parameters_file, observation_file, filter_type, summary_stat_type
)

