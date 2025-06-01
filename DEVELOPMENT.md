# Development Guide

Development guide for contributing to v0-mcp-ts.

## 📁 Project Structure

```
v0-mcp-ts/
├── .github/
│   └── workflows/          # GitHub Actions CI/CD (using Bun)
├── src/
│   └── index.ts           # Main MCP server
├── tests/
│   ├── setup.ts           # Test configuration
│   ├── server.test.ts     # Server tests
│   └── tools.test.ts      # Tool tests
├── scripts/
│   └── setup.js           # Setup script
├── examples/
│   └── claude-config.json # Configuration example
├── package.json           # Dependencies and scripts
├── tsconfig.json          # TypeScript configuration
├── vitest.config.ts       # Testing configuration
├── bun.lock               # Bun lockfile (faster than package-lock.json)
├── Dockerfile             # Container configuration
├── docker-compose.yml     # Multi-service setup
└── README.md              # Main documentation
```

## 🛠️ Development Setup

### 1. Clone & Install

```bash
git clone https://github.com/nicotordev/v0-mcp-ts.git
cd v0-mcp-ts
bun install  # ⚡ Up to 25x faster than npm install
```

### 2. Environment Configuration

```bash
cp .env.example .env
# Edit .env with your v0dev API key
```

### 3. Development with Watch Mode

```bash
bun run dev
```

This command starts the server in development mode with auto-reload using Bun's native watch mode.

## 🏗️ MCP Server Architecture

### Core Components

1. **McpServer**: Main server handling MCP protocol
2. **Tools**: Functions exposing v0dev functionality
3. **Resources**: Static resources like documentation
4. **Prompts**: Predefined templates for interactions

### Data Flow

```
MCP Client → Transport (stdio) → MCP Server → v0dev API → Response
```

## 🔧 Adding New Tools

### Basic Pattern

```typescript
server.tool(
  'tool_name',
  {
    // Parameter validation with Zod
    param1: z.string().describe('Parameter description'),
    param2: z.number().optional().describe('Optional parameter'),
  },
  async ({ param1, param2 }) => {
    try {
      // Tool logic
      const result = await generateText({
        model: v0Model,
        prompt: `Custom prompt with ${param1}`,
        maxTokens: 3000,
      });

      return {
        content: [
          {
            type: 'text',
            text: result.text,
          },
        ],
        metadata: {
          usage: result.usage,
          // Additional metadata
        },
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error: ${
              error instanceof Error ? error.message : 'Unknown error'
            }`,
          },
        ],
        isError: true,
      };
    }
  }
);
```

### Best Practices for Tools

1. **Validation**: Use Zod to validate all parameters
2. **Description**: Include clear descriptions for each parameter
3. **Error Handling**: Always handle errors and return appropriate responses
4. **Metadata**: Include useful information in metadata
5. **Limits**: Respect API token limits

### Example: Code Analysis Tool

```typescript
server.tool(
  'analyze_code',
  {
    code: z.string().describe('Code to analyze'),
    analysis_type: z
      .enum(['security', 'performance', 'style', 'bugs'])
      .describe('Type of analysis to perform'),
    language: z
      .string()
      .optional()
      .default('typescript')
      .describe('Programming language'),
  },
  async ({ code, analysis_type, language }) => {
    try {
      const prompt = `Analyze this ${language} code for ${analysis_type} issues:

\`\`\`${language}
${code}
\`\`\`

Provide:
1. Issues found
2. Severity levels
3. Recommendations
4. Fixed code examples`;

      const result = await generateText({
        model: v0Model,
        prompt,
        maxTokens: 3000,
      });

      return {
        content: [
          {
            type: 'text',
            text: result.text,
          },
        ],
        metadata: {
          analysis_type,
          language,
          usage: result.usage,
        },
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error analyzing code: ${
              error instanceof Error ? error.message : 'Unknown error'
            }`,
          },
        ],
        isError: true,
      };
    }
  }
);
```

## 📚 Adding New Resources

### Basic Pattern

```typescript
server.resource('resource_name', 'custom://resource-uri', async (uri) => ({
  contents: [
    {
      uri: uri.href,
      mimeType: 'text/markdown', // or appropriate type
      text: 'Resource content',
    },
  ],
}));
```

### Dynamic Resources

```typescript
server.resource(
  'dynamic_resource',
  new ResourceTemplate('api://{endpoint}', { list: undefined }),
  async (uri, { endpoint }) => {
    const data = await fetchDataFromAPI(endpoint);
    return {
      contents: [
        {
          uri: uri.href,
          mimeType: 'application/json',
          text: JSON.stringify(data, null, 2),
        },
      ],
    };
  }
);
```

## 🧪 Testing

### Test Structure

```typescript
describe('Tool Name', () => {
  let client: Client;

  beforeAll(async () => {
    // MCP client setup
  });

  afterAll(async () => {
    // Cleanup
  });

  it('should handle normal case', async () => {
    const result = await client.callTool({
      name: 'tool_name',
      arguments: {
        /* args */
      },
    });

    expect(result).toBeDefined();
    expect(result.content).toBeDefined();
    // More assertions...
  });

  it('should handle error case', async () => {
    // Error handling test
  });
});
```

### Running Tests with Bun

```bash
# All tests (using Bun's fast test runner)
bun test

# Specific tests
bun test tools.test.ts

# UI tests
bun run test:ui

# Coverage report (with @vitest/coverage-v8)
bun run test:coverage

# Watch mode
bun run test:watch
```

## 🐳 Docker Development

### Build and Run

```bash
# Build Docker image
bun run docker:build

# Run with environment variables
bun run docker:run

# Development with Docker Compose
bun run docker:dev

# Testing with Docker Compose
bun run docker:test
```

### Docker Services

- **v0-mcp-ts**: Production container
- **v0-mcp-ts-dev**: Development container with hot reload
- **test**: Testing container

## 🔍 Debugging

### Server Debug

```bash
# With detailed logs
DEBUG=true bun run dev
```

### Test Debug

```bash
# With verbose Vitest logs
bun test --reporter=verbose
```

### MCP Client Debug

```typescript
// In client code
client.setRequestHandler('notification', (notification) => {
  console.log('Server notification:', notification);
});
```

## 🤝 Contributing

### Contribution Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and add tests
4. Verify all tests pass: `bun test`
5. Verify build: `bun run build`
6. Commit: `git commit -m 'Add amazing feature'`
7. Push: `git push origin feature/amazing-feature`
8. Create Pull Request

### Quality Criteria

- [ ] All tests pass
- [ ] TypeScript code without errors
- [ ] Updated documentation
- [ ] Proper error handling
- [ ] Zod parameter validation
- [ ] Useful metadata in responses

### Checklist for New Tools

- [ ] Function implemented in `src/index.ts`
- [ ] Tests in `tests/tools.test.ts`
- [ ] Documentation in `README.md`
- [ ] Usage example
- [ ] Error handling
- [ ] Parameter validation

## 🚀 CI/CD Pipeline

### GitHub Actions Workflows

1. **Quality Test** (`quality-test.yml`):

   - Uses Bun for all operations (install, test, build)
   - Runs on push/PR to main/develop
   - Security audit with `bun audit`
   - TypeScript checking with `bun run type-check`
   - Test coverage with `@vitest/coverage-v8`
   - Build verification

2. **Release** (`release.yml`):
   - Triggered by version tags
   - Creates GitHub releases
   - Publishes to npm (with Bun)
   - Builds and pushes Docker images

### Creating a Release

```bash
# Create and push a new version
bun run release

# Or manually:
bun version patch  # or minor, major
git push && git push --tags
```

## 📊 v0dev API

### Limits and Considerations

- Maximum 200 messages per day
- Context window: 128,000 tokens
- Maximum output: 32,000 tokens
- Requires Premium or Team plan

### Prompt Optimization

1. **Be Specific**: Include detailed context
2. **Structure Well**: Use clear format
3. **Token Limits**: Control length
4. **Examples**: Include examples when useful

### Optimized Prompt Example

```typescript
const prompt = `Create a ${framework} component named "${componentName}":

Requirements:
- ${description}
- Framework: ${framework}
- TypeScript support
- Proper error handling
- Accessible design

${
  props.length > 0
    ? `Props:
${props
  .map(
    (p) => `- ${p.name}: ${p.type} ${p.required ? '(required)' : '(optional)'}`
  )
  .join('\n')}`
    : ''
}

Please provide:
1. Complete component code
2. TypeScript interfaces
3. Usage example
4. CSS/styling
5. Test example

Format as markdown with proper code blocks.`;
```

## 🔧 Troubleshooting

### Common Errors

1. **"V0_API_KEY environment variable is required"**

   - Verify `.env` exists and contains the API key

2. **"Transport connection failed"**

   - Verify build completed: `bun run build`
   - Verify path in client configuration

3. **"Tool validation error"**

   - Verify parameters meet Zod schema
   - Check data types sent

4. **Rate limit errors**

   - Respect v0dev API limits
   - Implement retry logic if necessary

5. **Bun installation issues**
   - Update Bun: `bun upgrade`
   - Clear cache: `bun pm cache rm`
   - Reinstall dependencies: `rm -rf node_modules bun.lock && bun install`

### Debug Logs

```typescript
// In src/index.ts
console.error('Debug info:', {
  tool: 'tool_name',
  args: arguments,
  timestamp: new Date().toISOString(),
});
```

## ⚡ Bun Advantages

### Performance Benefits

- **25x faster** package installation than npm
- **Native TypeScript support** without transpilation
- **Built-in test runner** with Jest compatibility
- **Hot reload** with native watch mode
- **Bundle size optimization**

### Bun-Specific Commands

```bash
# Package management
bun install              # Install dependencies
bun add <package>        # Add dependency
bun remove <package>     # Remove dependency
bun update               # Update all dependencies
bun audit                # Security audit (v1.2.15+)

# Development
bun run dev              # Start development server
bun run build            # Build project
bun test                 # Run tests
bun --watch src/index.ts # Watch mode

# Utilities
bun upgrade              # Update Bun itself
bun pm cache rm          # Clear package cache
bun --version            # Check Bun version
```

## 📖 Useful Resources

- [Bun Documentation](https://bun.sh/docs)
- [Bun GitHub Actions Guide](https://bun.sh/guides/runtime/cicd)
- [MCP Documentation](https://modelcontextprotocol.io/)
- [v0dev API](https://vercel.com/docs/v0/api)
- [AI SDK](https://sdk.vercel.ai/)
- [Zod Documentation](https://zod.dev/)
- [Vitest Documentation](https://vitest.dev/)
- [Docker Documentation](https://docs.docker.com/)

---

## 👨‍💻 Maintainer

**Nicolas Torres**

- 🌍 Location: Chile 🇨🇱
- 🐙 GitHub: [@nicotordev](https://github.com/nicotordev)
- 💼 LinkedIn: [nicotordev](https://www.linkedin.com/in/nicotordev/)
- 🎥 YouTube: [NicoTorDev Channel](https://www.youtube.com/channel/UCcOj4lCqvmND56JDz1ZMWuA)

Full Stack Web Developer specializing in Node.js, React.js, Next.js, Vue.js, and modern web technologies with expertise in Bun runtime optimization.
