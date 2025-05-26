# Email-as-ENS Registrar

A registrar that allows users to claim ENS names based on their email ownership using zk-email proofs.

## Overview

This project enables users to claim ENS names corresponding to their email addresses. For example, if you own "myemail@example.com", you can claim "myemail@example.com.email.eth" and set any Ethereum address as the owner.

The system uses zk-email proofs to verify email ownership, ensuring that only the legitimate owner of an email address can claim the corresponding ENS name.

## Installing Dependencies

Install dependency:

```bash
yarn install
```

## Useful commands

Build smart contracts:

```bash
yarn build
```

Clean build artifacts and cache :

```bash
yarn clean
```

Generate test coverage:

```bash
yarn coverage
```

Format files:

```bash
yarn fmt
```

Lint files:

```bash
yarn lint
```

Run tests:

```bash
yarn test
```

## License

This project is licensed under MIT.
