ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(StackoverflowClone.Repo, :manual)

# Existing mocks
Mox.defmock(StackoverflowClone.StackOverflowClientMock,
  for: StackoverflowClone.StackOverflowClientBehaviour
)

Mox.defmock(StackoverflowClone.AI.LLMManagerMock, for: StackoverflowClone.AI.LLMManagerBehaviour)

# Reel pipeline mocks
Mox.defmock(StackoverflowClone.Media.DownloaderMock,
  for: StackoverflowClone.Media.Downloader
)

Mox.defmock(StackoverflowClone.Media.AudioExtractorMock,
  for: StackoverflowClone.Media.AudioExtractor
)

Mox.defmock(StackoverflowClone.Media.MetadataExtractorMock,
  for: StackoverflowClone.Media.MetadataExtractor
)

Mox.defmock(StackoverflowClone.Slack.ClientMock,
  for: StackoverflowClone.Slack.Client
)

Mox.defmock(StackoverflowClone.Transcription.ProviderMock,
  for: StackoverflowClone.Transcription.Behaviour
)

Mox.defmock(StackoverflowClone.LLM.ProviderMock,
  for: StackoverflowClone.LLM.SummarizerBehaviour
)
