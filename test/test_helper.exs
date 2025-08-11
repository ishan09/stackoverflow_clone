ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(StackoverflowClone.Repo, :manual)

# Define mocks
Mox.defmock(StackoverflowClone.StackOverflowClientMock,
  for: StackoverflowClone.StackOverflowClientBehaviour
)

Mox.defmock(StackoverflowClone.AI.LLMManagerMock, for: StackoverflowClone.AI.LLMManagerBehaviour)
