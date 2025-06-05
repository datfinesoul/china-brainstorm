# TODO - WordPress China Deployment

## RDS Enhanced Monitoring
- **Cost**: ~$14.40/month additional
- **Benefit**: Detailed OS-level metrics (CPU, memory, file system, network)
- **Decision**: Removed from initial deployment to reduce costs
- **Future**: Consider enabling for production troubleshooting if needed
- **Implementation**: Add monitoring_interval = 60 and monitoring_role_arn to RDS instance
